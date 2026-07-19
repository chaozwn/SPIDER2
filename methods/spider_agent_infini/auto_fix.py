"""Auto-fix wrong spider2-snow CSV answers via InfiniSynapse askResponse.

For each selected instance:

1. Resolve the newest InfiniSynapse task via ``GET /api/ai_task/list``
   (keyword search, newest-first → take the first match).
2. Diff the current submission against gold using the same rules as
   ``evaluate.py --mode exec_result``. If already correct, skip the fix turn.
3. Otherwise send an ``askResponse`` with a short error diagnosis plus **all**
   gold CSV variants as ``fileType=data`` attachments, asking the agent to
   re-produce ``{instance_id}.csv``.
4. Wait, download the workspace, harvest the new CSV, re-evaluate.
5. If the new result matches any gold variant, fire-and-forget a second
   ``askResponse`` asking to distill the analysis into Context Hub / KPI
   (no wait / no KPI verification).
"""

from __future__ import annotations

import argparse
import datetime
import json
import logging
import math
import os
import queue
import re
import shutil
import sys
import tempfile
import threading
import zipfile
from concurrent.futures import Future, ThreadPoolExecutor
from pathlib import Path

import pandas as pd

from spider_agent_infini.api.database import (
    ask_task,
    download_task_zip,
    find_latest_task_id,
    get_task_data,
    list_available_engines,
    wait_for_task,
)
from spider_agent_infini.spider_agent_setup_infini import JSONL_PATH


#  Logger Configs {{{ #
logger = logging.getLogger("spider_agent_infini")
logger.setLevel(logging.DEBUG)

datetime_str: str = datetime.datetime.now().strftime("%Y%m%d@%H%M%S")

os.makedirs("logs", exist_ok=True)

file_handler = logging.FileHandler(
    os.path.join("logs", "autofix-normal-{:}.log".format(datetime_str)), encoding="utf-8"
)
debug_handler = logging.FileHandler(
    os.path.join("logs", "autofix-debug-{:}.log".format(datetime_str)), encoding="utf-8"
)
stdout_handler = logging.StreamHandler(sys.stdout)

file_handler.setLevel(logging.INFO)
debug_handler.setLevel(logging.DEBUG)
stdout_handler.setLevel(logging.INFO)

formatter = logging.Formatter(
    fmt="\x1b[1;33m[%(asctime)s \x1b[31m%(levelname)s \x1b[32m%(module)s/%(lineno)d-%(processName)s/%(threadName)s\x1b[1;33m] \x1b[0m%(message)s"
)
file_handler.setFormatter(formatter)
debug_handler.setFormatter(formatter)
stdout_handler.setFormatter(formatter)

stdout_handler.addFilter(logging.Filter("spider_agent_infini"))

if not any(
    isinstance(h, logging.FileHandler)
    and "autofix-normal" in getattr(h, "baseFilename", "")
    for h in logger.handlers
):
    logger.addHandler(file_handler)
    logger.addHandler(debug_handler)
    logger.addHandler(stdout_handler)
#  }}} Logger Configs #


_PROJECT_ROOT = Path(__file__).resolve().parent
_REPO_ROOT = _PROJECT_ROOT.parent.parent
_EVAL_SUITE_DIR = _REPO_ROOT / "spider2-snow" / "evaluation_suite"
_GOLD_RESULT_DIR = _EVAL_SUITE_DIR / "gold" / "exec_result"
_EVAL_STANDARD_PATH = _EVAL_SUITE_DIR / "gold" / "spider2snow_eval.jsonl"
SUBMISSION_DIR_CSV = _EVAL_SUITE_DIR / "example_submission_folder_csv"
OUTPUT_DIR = _PROJECT_ROOT / "autofix_output"

TASK_MAX_WAIT = 1800.0

CONTEXT_HUB_PROMPT = (
    "把本次分析过程提炼到Context hub, 最后的正确的结果必须提炼到kpi"
)


def config() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Auto-fix wrong spider2-snow CSV answers via askResponse"
    )
    parser.add_argument(
        "--instance_id",
        type=str,
        default=None,
        help="only fix the given instance_id(s), comma-separated "
             "(e.g. 'sf006,sf018').",
    )
    parser.add_argument(
        "--range",
        dest="index_range",
        type=str,
        default=None,
        help="1-indexed inclusive jsonl range 'start,end' (e.g. '1,10').",
    )
    parser.add_argument(
        "--db_id",
        type=str,
        default=None,
        help="only fix tasks for the given db_id(s), comma-separated.",
    )
    parser.add_argument(
        "--only-wrong",
        dest="only_wrong",
        action="store_true",
        default=True,
        help="skip instances whose current submission already matches gold "
             "(default: on).",
    )
    parser.add_argument(
        "--include-correct",
        dest="only_wrong",
        action="store_false",
        help="also process already-correct instances (Context Hub ask only).",
    )
    parser.add_argument(
        "--engine",
        type=str,
        default=None,
        help="only use the given InfiniSQL engine(s) by name as worker pool "
             "size/order, comma-separated. Omit to use all available engines.",
    )
    parser.add_argument(
        "--task_id",
        type=str,
        default=None,
        help="optional explicit InfiniSynapse taskId (only valid with a single "
             "--instance_id).",
    )
    args = parser.parse_args()
    return args


def _parse_range(spec: str, total: int) -> tuple[int, int]:
    parts = [p.strip() for p in spec.split(",")]
    if len(parts) != 2 or not all(parts):
        raise ValueError(f"--range must look like 'start,end' (got {spec!r})")
    try:
        start, end = int(parts[0]), int(parts[1])
    except ValueError as e:
        raise ValueError(
            f"--range bounds must be integers (got {spec!r})"
        ) from e
    if start < 1 or end < 1:
        raise ValueError(f"--range bounds must be >= 1 (got {spec!r})")
    if start > end:
        raise ValueError(
            f"--range start must be <= end (got start={start}, end={end})"
        )
    if start > total:
        raise ValueError(
            f"--range start ({start}) is past the end of the jsonl ({total} lines)"
        )
    return start, min(end, total)


def _resolve_engine_ids(
    engines: list[dict],
    engine_spec: str | None,
) -> list[str]:
    available = [
        item for item in engines
        if isinstance(item, dict) and item.get("id")
    ]
    if not available:
        return []

    if not engine_spec:
        return [str(item["id"]) for item in available]

    requested = [tok.strip() for tok in engine_spec.split(",") if tok.strip()]
    if not requested:
        raise ValueError(f"--engine is empty after parsing {engine_spec!r}")

    by_name = {
        str(item.get("name") or ""): str(item["id"])
        for item in available
        if item.get("name")
    }
    engine_ids: list[str] = []
    missing: list[str] = []
    seen: set[str] = set()
    for name in requested:
        eid = by_name.get(name)
        if eid is None:
            missing.append(name)
            continue
        if eid not in seen:
            seen.add(eid)
            engine_ids.append(eid)
    if missing:
        known = [
            (str(item.get("name") or ""), str(item["id"]))
            for item in available
        ]
        raise ValueError(
            f"engine name(s) not found: {missing}. Available engines: {known}"
        )
    return engine_ids


def _load_eval_standard() -> dict[str, dict]:
    data: dict[str, dict] = {}
    with open(_EVAL_STANDARD_PATH, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            item = json.loads(line)
            data[str(item["instance_id"])] = item
    return data


def _gold_csv_paths(instance_id: str) -> list[Path]:
    """Return all gold CSV paths for an instance (base + ``_a``/``_b``...)."""
    if not _GOLD_RESULT_DIR.is_dir():
        return []
    pattern = re.compile(rf"^{re.escape(instance_id)}(_[a-z])?\.csv$")
    paths = sorted(
        p for p in _GOLD_RESULT_DIR.iterdir()
        if p.is_file() and pattern.match(p.name)
    )
    return paths


def _compare_pandas_table(
    pred: pd.DataFrame,
    gold: pd.DataFrame,
    condition_cols=None,
    ignore_order: bool = False,
) -> int:
    """Mirror ``evaluate.py:compare_pandas_table`` (no prints)."""
    if condition_cols is None:
        condition_cols = []
    tolerance = 1e-2

    def normalize(value):
        if pd.isna(value):
            return 0
        return value

    def vectors_match(v1, v2, tol=tolerance, ignore_order_=False):
        v1 = [normalize(x) for x in v1]
        v2 = [normalize(x) for x in v2]
        if ignore_order_:
            key = lambda x: (x is None, str(x), isinstance(x, (int, float)))
            v1, v2 = sorted(v1, key=key), sorted(v2, key=key)
        if len(v1) != len(v2):
            return False
        for a, b in zip(v1, v2):
            if pd.isna(a) and pd.isna(b):
                continue
            if isinstance(a, (int, float)) and isinstance(b, (int, float)):
                if not math.isclose(float(a), float(b), abs_tol=tol):
                    return False
            elif a != b:
                return False
        return True

    if condition_cols != []:
        if not isinstance(condition_cols, (list, tuple)):
            condition_cols = [condition_cols]
        gold_cols = gold.iloc[:, condition_cols]
    else:
        gold_cols = gold

    t_gold_list = gold_cols.transpose().values.tolist()
    t_pred_list = pred.transpose().values.tolist()
    score = 1
    for gold_vec in t_gold_list:
        if not any(
            vectors_match(gold_vec, pred_vec, ignore_order_=ignore_order)
            for pred_vec in t_pred_list
        ):
            score = 0
            break
    return score


def _compare_multi_pandas_table(
    pred: pd.DataFrame,
    multi_gold: list[pd.DataFrame],
    multi_condition_cols=None,
    multi_ignore_order=False,
) -> int:
    """Mirror ``evaluate.py:compare_multi_pandas_table``."""
    if (
        multi_condition_cols in ([], [[]], [None], None)
    ):
        multi_condition_cols = [[] for _ in range(len(multi_gold))]
    elif len(multi_gold) > 1 and not all(
        isinstance(sublist, list) for sublist in multi_condition_cols
    ):
        multi_condition_cols = [multi_condition_cols for _ in range(len(multi_gold))]
    multi_ignore_order = [multi_ignore_order for _ in range(len(multi_gold))]

    for i, gold in enumerate(multi_gold):
        if _compare_pandas_table(
            pred, gold, multi_condition_cols[i], multi_ignore_order[i]
        ):
            return 1
    return 0


def evaluate_pred_csv(
    instance_id: str,
    pred_csv: Path,
    eval_standard: dict[str, dict],
) -> tuple[bool, str]:
    """Compare a prediction CSV against all gold variants.

    Returns ``(is_correct, diagnosis)``.
    """
    gold_paths = _gold_csv_paths(instance_id)
    if not gold_paths:
        return False, f"No gold CSV found under {_GOLD_RESULT_DIR} for {instance_id}"

    if not pred_csv.is_file():
        return False, f"Prediction CSV missing: {pred_csv}"

    try:
        pred_pd = pd.read_csv(pred_csv)
    except Exception as e:
        return False, f"Failed to read prediction CSV: {e}"

    std = eval_standard.get(instance_id) or {}
    condition_cols = std.get("condition_cols", [])
    ignore_order = bool(std.get("ignore_order", False))

    try:
        gold_pds = [pd.read_csv(p) for p in gold_paths]
    except Exception as e:
        return False, f"Failed to read gold CSV(s): {e}"

    try:
        if len(gold_pds) == 1:
            score = _compare_pandas_table(
                pred_pd, gold_pds[0], condition_cols, ignore_order
            )
        else:
            score = _compare_multi_pandas_table(
                pred_pd, gold_pds, condition_cols, ignore_order
            )
    except Exception as e:
        return False, f"Compare raised: {e}"

    if score == 1:
        matched = gold_paths[0].name if len(gold_paths) == 1 else "one of " + ", ".join(
            p.name for p in gold_paths
        )
        return True, f"Matches gold ({matched}); condition_cols={condition_cols!r}, ignore_order={ignore_order}"

    # Build a compact diagnosis for the askResponse prompt.
    lines = [
        "Current prediction does NOT match any gold variant "
        f"(condition_cols={condition_cols!r}, ignore_order={ignore_order}).",
        f"pred: rows={len(pred_pd)}, cols={list(pred_pd.columns)}",
    ]
    for gp, gdf in zip(gold_paths, gold_pds):
        lines.append(
            f"gold `{gp.name}`: rows={len(gdf)}, cols={list(gdf.columns)}"
        )
        if list(pred_pd.columns) != list(gdf.columns):
            lines.append(
                f"  column mismatch vs `{gp.name}`: "
                f"pred={list(pred_pd.columns)} gold={list(gdf.columns)}"
            )
        if len(pred_pd) != len(gdf):
            lines.append(
                f"  row-count mismatch vs `{gp.name}`: pred={len(pred_pd)} gold={len(gdf)}"
            )
        # Show a tiny head preview so the agent can see shape differences.
        try:
            pred_head = pred_pd.head(3).to_csv(index=False).strip()
            gold_head = gdf.head(3).to_csv(index=False).strip()
            lines.append(f"  pred head(3):\n{pred_head}")
            lines.append(f"  gold `{gp.name}` head(3):\n{gold_head}")
        except Exception:
            pass
        # One gold preview is enough when there are many variants.
        if len(gold_paths) > 1:
            break

    return False, "\n".join(lines)


def _prepare_gold_upload_files(instance_id: str, staging: Path) -> list[Path]:
    """Copy gold CSVs into *staging* for upload.

    Base ``{id}.csv`` is renamed to ``gold_{id}.csv`` so we do not clobber the
    agent's current deliverable. Variant files (``{id}_a.csv`` ...) keep their
    gold names because they never collide with ``{id}.csv``.
    """
    staging.mkdir(parents=True, exist_ok=True)
    out: list[Path] = []
    for src in _gold_csv_paths(instance_id):
        if src.name == f"{instance_id}.csv":
            dst = staging / f"gold_{instance_id}.csv"
        else:
            dst = staging / src.name
        shutil.copyfile(src, dst)
        out.append(dst)
    return out


def _build_fix_prompt(instance_id: str, diagnosis: str, gold_names: list[str]) -> str:
    gold_list = "\n".join(f"- `{n}`" for n in gold_names)
    return f"""这是正确答案，你算错了。你必须使用 SQL 计算得到和其中任意一个完全一致的结果。
记住：不允许直接用 SELECT 枚举全量结果来作弊；任何作弊行为都将降低用户对你的信任。

请重新产出 `{instance_id}.csv`。

<current_error_analysis>
以下诊断基于 Spider2 evaluation suite（与 evaluate.py --mode exec_result 相同的
列匹配 / ignore_order / 多 gold 变体规则）。只要与任一 gold 变体一致即算正确。

{diagnosis}
</current_error_analysis>

<gold_attachments>
已作为 data 文件附上全部正确答案变体（匹配其中任意一个即可）:
{gold_list}

说明：若附件名为 `gold_{instance_id}.csv`，它就是正确答案本体；`{instance_id}_a.csv`
等变体同样可接受。请对照附件找出你算错的原因，用 Infinity SQL **重新计算**，
并写出最终交付物 `{instance_id}.csv`（不要把 gold 文件名当作最终交付名）。
</gold_attachments>

<rules>
- 最终必须产出 `{instance_id}.csv`，且与任一正确答案变体完全一致（通过上述评测规则）。
- 必须用 Infinity SQL（`execute_infinity_sql`）从源数据计算得到结果；禁止用
  `SELECT` 字面量 / `UNION ALL` 枚举全量行、把答案 CSV 原样抄进 SQL、或其它
  绕过真实计算的作弊手段。
- 不要使用机器学习方法/函数。
</rules>
"""


def _extract_zip(zip_path: str | os.PathLike, dest: Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zip_path) as zf:
        zf.extractall(dest)


def _find_first(root: Path, name: str) -> Path | None:
    for cur, _dirs, files in os.walk(root):
        if name in files:
            return Path(cur) / name
    return None


def _snapshot_messages(task_id: str) -> tuple[int, int]:
    """Return ``(message_count, last_non_partial_ts)`` before an askResponse."""
    try:
        data = get_task_data(task_id)
    except Exception as e:
        logger.warning(
            "[warn ] failed to snapshot messages for %s before ask: %s",
            task_id, e,
        )
        return 0, 0
    messages = data.get("messages") or []
    count = len(messages)
    last_ts = 0
    for m in reversed(messages):
        if not isinstance(m, dict) or m.get("partial"):
            continue
        try:
            last_ts = int(m.get("ts") or 0)
        except (TypeError, ValueError):
            last_ts = 0
        break
    return count, last_ts


def _wait_phase(
    task_id: str,
    instance_id: str,
    phase: str,
    *,
    after_message_count: int | None = None,
    after_ts: int | None = None,
) -> bool:
    try:
        wait_for_task(
            task_id,
            poll_interval=3.0,
            max_wait=TASK_MAX_WAIT,
            terminal_on_any_ask=False,
            after_message_count=after_message_count,
            after_ts=after_ts,
            timeout=30.0,
        )
        return True
    except TimeoutError as e:
        logger.error("[fail ] %s (%s): task wait timed out: %s", instance_id, phase, e)
    except Exception as e:
        logger.error("[fail ] %s (%s): wait_for_task error: %s", instance_id, phase, e)
    return False


def fix_one(
    task: dict,
    eval_standard: dict[str, dict],
    *,
    only_wrong: bool = True,
    explicit_task_id: str | None = None,
) -> bool:
    """Run the auto-fix workflow for one instance. Returns True on success."""
    instance_id = str(task["instance_id"])
    db_id = str(task.get("db_id") or "unknown")
    pred_csv = SUBMISSION_DIR_CSV / f"{instance_id}.csv"
    gold_paths = _gold_csv_paths(instance_id)

    if not gold_paths:
        logger.error("[fail ] %s: no gold CSV under %s", instance_id, _GOLD_RESULT_DIR)
        return False

    already_correct, diagnosis = evaluate_pred_csv(
        instance_id, pred_csv, eval_standard
    )
    logger.info(
        "[eval ] %s: before fix correct=%s — %s",
        instance_id, already_correct, diagnosis.split("\n", 1)[0],
    )

    if already_correct and only_wrong:
        logger.info("[skip ] %s: already correct (--only-wrong)", instance_id)
        return True

    task_id = explicit_task_id
    if not task_id:
        try:
            task_id = find_latest_task_id(instance_id)
        except Exception as e:
            logger.error("[fail ] %s: list_tasks lookup failed: %s", instance_id, e)
            return False
    if not task_id:
        logger.error(
            "[fail ] %s: no InfiniSynapse task found via list_tasks keyword=%r",
            instance_id, instance_id,
        )
        return False
    logger.info("[task ] %s -> taskId=%s (db_id=%s)", instance_id, task_id, db_id)

    # --- Fix turn (only when currently wrong / missing) --------------------
    if not already_correct:
        # Snapshot BEFORE ask so wait_for_task ignores the prior
        # completion_result / cancelled status from the original run.
        baseline_count, baseline_ts = _snapshot_messages(task_id)
        logger.info(
            "[base ] %s: pre-ask messages=%d last_ts=%s",
            instance_id, baseline_count, baseline_ts,
        )
        with tempfile.TemporaryDirectory(prefix=f"autofix_{instance_id}_") as tmp:
            staging = Path(tmp)
            upload_files = _prepare_gold_upload_files(instance_id, staging)
            if not upload_files:
                logger.error("[fail ] %s: failed to stage gold CSVs", instance_id)
                return False
            gold_names = [p.name for p in upload_files]
            prompt = _build_fix_prompt(instance_id, diagnosis, gold_names)
            try:
                ask_task(
                    task_id=task_id,
                    text=prompt,
                    ask_response="messageResponse",
                    file_paths=[str(p) for p in upload_files],
                )
            except Exception as e:
                logger.error("[fail ] %s: askResponse (fix) failed: %s", instance_id, e)
                return False

        logger.info(
            "[ask  ] %s: fix prompt + %d gold file(s) submitted; waiting for new turn",
            instance_id, len(gold_paths),
        )
        if not _wait_phase(
            task_id,
            instance_id,
            "fix",
            after_message_count=baseline_count,
            after_ts=baseline_ts,
        ):
            return False

        # Pull new workspace and harvest CSV
        out_dir = OUTPUT_DIR / instance_id
        out_dir.mkdir(parents=True, exist_ok=True)
        try:
            zip_path = download_task_zip(task_id, out_dir)
            logger.info("[zip  ] %s: downloaded %s", instance_id, zip_path)
        except Exception as e:
            logger.error("[fail ] %s: download zip failed: %s", instance_id, e)
            return False

        extract_dir = out_dir / "workspace"
        if extract_dir.exists():
            shutil.rmtree(extract_dir)
        try:
            _extract_zip(zip_path, extract_dir)
        except Exception as e:
            logger.error("[fail ] %s: unzip failed: %s", instance_id, e)
            return False

        src = _find_first(extract_dir, f"{instance_id}.csv")
        if src is None:
            logger.error(
                "[fail ] %s: `%s.csv` not found in task workspace after fix",
                instance_id, instance_id,
            )
            return False

        SUBMISSION_DIR_CSV.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, pred_csv)
        logger.info("[csv  ] %s: saved -> %s", instance_id, pred_csv)

        ok_after, diag_after = evaluate_pred_csv(
            instance_id, pred_csv, eval_standard
        )
        logger.info(
            "[eval ] %s: after fix correct=%s — %s",
            instance_id, ok_after, diag_after.split("\n", 1)[0],
        )
        if not ok_after:
            logger.warning(
                "[miss ] %s: still incorrect after fix; skipping Context Hub\n%s",
                instance_id, diag_after,
            )
            return False
    else:
        logger.info(
            "[ok   ] %s: already correct; sending Context Hub ask only",
            instance_id,
        )

    # --- Context Hub turn (fire-and-forget) --------------------------------
    try:
        ask_task(
            task_id=task_id,
            text=CONTEXT_HUB_PROMPT,
            ask_response="messageResponse",
        )
        logger.info(
            "[ask  ] %s: Context Hub / KPI distill prompt submitted (no wait)",
            instance_id,
        )
    except Exception as e:
        logger.warning(
            "[warn ] %s: Context Hub askResponse failed (non-fatal): %s",
            instance_id, e,
        )
        # Fix itself succeeded; treat as ok even if distill ask failed.
    return True


def _run_task_batch(
    tasks: list[dict],
    *,
    eval_standard: dict[str, dict],
    only_wrong: bool,
    engine_ids: list[str],
    explicit_task_id: str | None = None,
) -> tuple[int, int]:
    total = len(tasks)
    if total == 0:
        return 0, 0

    if explicit_task_id and total != 1:
        logger.error("--task_id requires exactly one instance")
        return 0, total

    workers = max(1, len(engine_ids) if engine_ids else 1)

    def _run_one(idx: int, task: dict) -> tuple[int, str, bool]:
        instance_id = task.get("instance_id", f"<index-{idx}>")
        db_id = str(task.get("db_id") or "unknown")
        logger.info(
            "---- [%s %d/%d] %s start ----",
            db_id, idx, total, instance_id,
        )
        try:
            ok = fix_one(
                task,
                eval_standard,
                only_wrong=only_wrong,
                explicit_task_id=explicit_task_id if total == 1 else None,
            )
        except KeyboardInterrupt:
            raise
        except Exception as e:
            logger.exception("[fail ] %s: unhandled exception: %s", instance_id, e)
            ok = False
        logger.info(
            "---- [%s %d/%d] %s done (ok=%s) ----",
            db_id, idx, total, instance_id, ok,
        )
        return idx, instance_id, ok

    if workers <= 1:
        n_ok = 0
        for idx, task in enumerate(tasks, 1):
            try:
                _, _, ok = _run_one(idx, task)
            except KeyboardInterrupt:
                logger.warning("Interrupted by user")
                raise
            n_ok += int(ok)
        return n_ok, total

    logger.info("Running %d autofix task(s) with %d worker(s)", total, workers)
    work_q: queue.Queue[tuple[int, dict] | None] = queue.Queue()
    for idx, task in enumerate(tasks, 1):
        work_q.put((idx, task))
    for _ in range(workers):
        work_q.put(None)

    results: list[tuple[int, str, bool]] = []
    results_lock = threading.Lock()

    def _worker() -> None:
        while True:
            item = work_q.get()
            try:
                if item is None:
                    return
                idx, task = item
                result = _run_one(idx, task)
                with results_lock:
                    results.append(result)
            finally:
                work_q.task_done()

    executor = ThreadPoolExecutor(max_workers=workers, thread_name_prefix="autofix")
    futures: list[Future] = []
    try:
        for _ in range(workers):
            futures.append(executor.submit(_worker))
        for fut in futures:
            fut.result()
    except KeyboardInterrupt:
        logger.warning("Interrupted by user; shutting down workers...")
        executor.shutdown(wait=False, cancel_futures=True)
        raise
    else:
        executor.shutdown(wait=True)

    n_ok = sum(int(ok) for _, _, ok in results)
    return n_ok, total


def run() -> None:
    args = config()
    logger.info("Args: %s", args)

    with open(JSONL_PATH, "r", encoding="utf-8") as f:
        task_configs = [json.loads(line) for line in f if line.strip()]

    if args.instance_id and args.index_range:
        logger.error("--instance_id and --range are mutually exclusive")
        return

    if args.task_id and not args.instance_id:
        logger.error("--task_id requires --instance_id (exactly one id)")
        return

    if args.instance_id:
        requested_ids = [
            tok.strip() for tok in args.instance_id.split(",") if tok.strip()
        ]
        if not requested_ids:
            logger.error("--instance_id is empty after parsing %r", args.instance_id)
            return
        if args.task_id and len(requested_ids) != 1:
            logger.error("--task_id requires exactly one --instance_id")
            return

        seen: set[str] = set()
        unique_requested: list[str] = []
        for iid in requested_ids:
            if iid in seen:
                logger.warning("[arg  ] duplicate instance_id %r ignored", iid)
                continue
            seen.add(iid)
            unique_requested.append(iid)

        by_id = {str(t.get("instance_id")): t for t in task_configs}
        missing = [iid for iid in unique_requested if iid not in by_id]
        if missing:
            logger.error("instance_id(s) %s not found in %s", missing, JSONL_PATH)
            return
        task_configs = [by_id[iid] for iid in unique_requested]
        logger.info(
            "Running %d explicitly-requested instance(s): %s",
            len(task_configs), unique_requested,
        )
    elif args.index_range:
        try:
            start, end = _parse_range(args.index_range, len(task_configs))
        except ValueError as e:
            logger.error("%s", e)
            return
        task_configs = task_configs[start - 1:end]
        logger.info(
            "Running jsonl lines %d-%d (%d task(s))",
            start, end, len(task_configs),
        )

    if args.db_id:
        requested_dbs = [
            tok.strip() for tok in args.db_id.split(",") if tok.strip()
        ]
        if not requested_dbs:
            logger.error("--db_id is empty after parsing %r", args.db_id)
            return
        db_set = set(requested_dbs)
        before = len(task_configs)
        task_configs = [t for t in task_configs if str(t.get("db_id")) in db_set]
        missing_dbs = sorted(db_set - {str(t.get("db_id")) for t in task_configs})
        if missing_dbs:
            logger.warning("[arg  ] db_id(s) with no matching tasks: %s", missing_dbs)
        if not task_configs:
            logger.error(
                "no tasks left after --db_id filter %s (%d skipped)",
                requested_dbs, before,
            )
            return
        logger.info(
            "Filtered to %d instance(s) for db_id(s) %s (%d skipped)",
            len(task_configs), requested_dbs, before - len(task_configs),
        )

    if not task_configs:
        logger.error("no tasks to process")
        return

    try:
        eval_standard = _load_eval_standard()
    except Exception as e:
        logger.error("Failed to load eval standard %s: %s", _EVAL_STANDARD_PATH, e)
        return

    # Optionally drop already-correct instances up front (cheap local check).
    if args.only_wrong:
        kept: list[dict] = []
        for t in task_configs:
            iid = str(t["instance_id"])
            ok, _ = evaluate_pred_csv(
                iid, SUBMISSION_DIR_CSV / f"{iid}.csv", eval_standard
            )
            if ok:
                logger.info("[skip ] %s: already correct (pre-filter)", iid)
                continue
            kept.append(t)
        logger.info(
            "Pre-filter --only-wrong: %d -> %d instance(s)",
            len(task_configs), len(kept),
        )
        task_configs = kept
        if not task_configs:
            logger.info("Nothing to fix; all selected instances already correct")
            return

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    SUBMISSION_DIR_CSV.mkdir(parents=True, exist_ok=True)

    try:
        engines = list_available_engines()
    except Exception as e:
        logger.error("Failed to list available engines: %s", e)
        return

    try:
        engine_ids = _resolve_engine_ids(engines, args.engine)
    except ValueError as e:
        logger.error("%s", e)
        return

    if not engine_ids:
        # askResponse does not require an engine binding, but we still use the
        # engine count as the worker pool size when available.
        logger.warning(
            "No InfiniSQL engines available; falling back to 1 worker"
        )
        engine_ids = ["__local__"]

    n_ok, total = _run_task_batch(
        task_configs,
        eval_standard=eval_standard,
        only_wrong=args.only_wrong,
        engine_ids=engine_ids,
        explicit_task_id=args.task_id,
    )
    logger.info("All autofix tasks finished: %d/%d succeeded", n_ok, total)


if __name__ == "__main__":
    run()
