"""Distill Context Hub memory from spider2-snow Q&A pairs (gold SQL answers).

Unlike :mod:`run`, which asks the Agent to **solve** benchmark questions, this
runner gives the Agent a **question + reference answer SQL** in one prompt and
asks it to **distill Context Hub** only — not to answer or reproduce results.

- Reference SQL:
  ``spider2-snow/evaluation_suite/gold/sql/<instance_id>.sql``
- **KPI is mandatory**: at least one ``context_hub_submit_kpi`` whose
  ``sql_query`` is the final answer SQL.
- All Context Hub areas (table, column, kpi, user_preference, playbook) may
  yield **multiple** submissions; nothing is capped at one per type.

Tasks are **ordered by ``db_id``** by default. Filter with ``--db_id``;
use ``--no-group-by-db`` for jsonl order instead. All pending tasks share
one global engine queue (one in-flight task per engine).
"""

from __future__ import annotations

import argparse
import datetime
import json
import logging
import os
import queue
import sys
import threading
import uuid
from collections import OrderedDict
from concurrent.futures import Future, ThreadPoolExecutor
from pathlib import Path

from spider_agent_infini.api.database import (
    download_task_zip,
    get_task_data,
    list_available_engines,
    new_task,
    select_databases_by_snowflake_database,
    wait_for_task,
)
from spider_agent_infini.spider_agent_setup_infini import DOCUMENT_PATH, JSONL_PATH


TASK_MAX_WAIT = 1800.0


#  Logger Configs {{{ #
logger = logging.getLogger("spider_agent_infini")
logger.setLevel(logging.DEBUG)

datetime_str: str = datetime.datetime.now().strftime("%Y%m%d@%H%M%S")

os.makedirs("logs", exist_ok=True)

file_handler = logging.FileHandler(
    os.path.join("logs", "learn-normal-{:}.log".format(datetime_str)), encoding="utf-8"
)
debug_handler = logging.FileHandler(
    os.path.join("logs", "learn-debug-{:}.log".format(datetime_str)), encoding="utf-8"
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
    isinstance(h, logging.FileHandler) and "learn-normal" in getattr(h, "baseFilename", "")
    for h in logger.handlers
):
    logger.addHandler(file_handler)
    logger.addHandler(debug_handler)
    logger.addHandler(stdout_handler)
#  }}} Logger Configs #


_PROJECT_ROOT = Path(__file__).resolve().parent
_REPO_ROOT = _PROJECT_ROOT.parent.parent
_GOLD_SQL_DIR = _REPO_ROOT / "spider2-snow" / "evaluation_suite" / "gold" / "sql"
OUTPUT_DIR = _PROJECT_ROOT / "learn_output"


def config() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Learn Context Hub memory from spider2-snow Q&A (gold SQL)"
    )
    parser.add_argument(
        "--instance_id",
        type=str,
        default=None,
        help="only run the given instance_id(s), comma-separated "
             "(e.g. 'sf_local003,sf_local009').",
    )
    parser.add_argument(
        "--range",
        dest="index_range",
        type=str,
        default=None,
        help="1-indexed inclusive jsonl range 'start,end' (e.g. '1,10').",
    )
    parser.add_argument(
        "--rerun",
        "--force",
        dest="rerun",
        action="store_true",
        help="re-run even if a learn marker already exists for the instance.",
    )
    parser.add_argument(
        "--db_id",
        type=str,
        default=None,
        help="only run tasks for the given db_id(s), comma-separated "
             "(e.g. 'AIRLINES,PATENTS').",
    )
    parser.add_argument(
        "--all",
        dest="include_without_gold",
        action="store_true",
        help="include jsonl rows even when no gold SQL exists "
             "(those rows are skipped with a warning).",
    )
    parser.add_argument(
        "--group-by-db",
        dest="group_by_db",
        action="store_true",
        default=True,
        help="order tasks by db_id (same db contiguous) before feeding the "
             "global engine queue (default: on). Does not serialize per db.",
    )
    parser.add_argument(
        "--no-group-by-db",
        dest="group_by_db",
        action="store_false",
        help="disable db_id grouping; run in jsonl / filter order instead.",
    )
    args = parser.parse_args()
    return args


def _parse_range(spec: str, total: int) -> tuple[int, int]:
    """Parse a '<start>,<end>' 1-indexed inclusive range string."""
    parts = [p.strip() for p in spec.split(",")]
    if len(parts) != 2 or not all(parts):
        raise ValueError(
            f"--range must look like 'start,end' (got {spec!r})"
        )
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
    end = min(end, total)
    return start, end


def _gold_sql_path(instance_id: str) -> Path:
    return _GOLD_SQL_DIR / f"{instance_id}.sql"


def _marker_path(instance_id: str, db_id: str) -> Path:
    return OUTPUT_DIR / db_id / instance_id / "learn.json"


def _is_done(instance_id: str, db_id: str) -> bool:
    marker = _marker_path(instance_id, db_id)
    if not marker.is_file():
        return False
    try:
        data = json.loads(marker.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return False
    return bool(data.get("kpi_submitted"))


def _group_tasks_by_db(tasks: list[dict]) -> list[tuple[str, list[dict]]]:
    """Group tasks by db_id, preserving first-seen db order from *tasks*."""
    groups: OrderedDict[str, list[dict]] = OrderedDict()
    for task in tasks:
        db_id = str(task.get("db_id") or "unknown")
        groups.setdefault(db_id, []).append(task)
    return list(groups.items())


def _build_learn_prompt(instance_id: str, instruction: str, gold_sql: str) -> str:
    return f"""You are a Context Hub distillation Agent for a Snowflake database.

Your job is **NOT** to answer the business question, **NOT** to re-derive the
result, and **NOT** to produce `{instance_id}.sql`, CSV, or any other task
deliverable. The reference answer SQL is already provided below as ground
truth. Your sole objective is to distill durable, reusable Context Hub memory
from this Q&A pair.

<question>
{instruction}
</question>

<reference_answer_sql>
{gold_sql.strip()}
</reference_answer_sql>

<objective>
Follow the **context-hub-distillation** workflow:

1. Read the question and the reference answer SQL. You may use Infinity SQL
   (`execute_infinity_sql`) only to **verify schema semantics** (table/column
   meanings, join keys, encodings, grain) that help you write accurate Context
   Hub entries — do NOT re-solve the question or replace the reference SQL.
2. Harvest candidates across **all** memory areas: table/column semantics, KPIs,
   user preferences, playbooks.
3. Search existing Context Hub memory (`context_hub_search`) before submitting.
4. Submit every validated candidate via the appropriate `context_hub_submit_*`
   tools. **There is no limit** on how many items you submit per area — submit
   as many distinct, validated entries as the Q&A pair supports.

**KPI is mandatory — the answer SQL MUST be distilled into KPI.**
This is the single most important deliverable of this task. The reference
answer SQL above is not optional background: you **must** encode it as a KPI
via `context_hub_submit_kpi`. Do NOT finish after submitting only tables,
columns, preferences, or playbooks — without at least one KPI whose
`sql_query` contains the full answer SQL, the run is a failure.

Concretely:
- Submit at least one KPI via `context_hub_submit_kpi`.
- That KPI's `sql_query` **must** be the reference answer SQL above, copied
  **verbatim** (the script whose final SELECT answers the question). Do not
  paraphrase, shorten, or substitute a different query.
- Use the KPI fields to **distill** business meaning from the answer SQL:
  `kpi_name` and `kpi_description` should capture what the SQL computes
  (metric, grain, filters, unit, formula) so a future agent can reuse it
  without re-deriving the logic from scratch.
- `creation_mode`: `business_logic`
- `tables`: every source table the SQL depends on (`database_name` + `table_name`)

You may submit **additional** KPIs, tables, columns, preferences, and
playbooks beyond the mandatory answer-SQL KPI — as many as are genuinely
validated by this Q&A pair. Do not stop after a single submission per type.

Finish with a short report listing every Context Hub item you submitted (area,
name, create vs update). Explicitly call out which KPI carries the reference
answer SQL in `sql_query`.
</objective>

<rules>
- The reference answer SQL **must** appear in at least one submitted KPI's
  `sql_query`; submitting Context Hub entries without this KPI is invalid.
- Do NOT fabricate schema facts; verify non-obvious semantics against the
  database when needed.
- Do NOT use machine-learning methods/functions in Infinity SQL.
- Prefer fully-qualified table names (`database.schema.table`).
</rules>
"""


def _extract_kpi_submissions(task_data: dict) -> list[dict]:
    """Return parsed context_hub_submit_kpi_result payloads from task messages."""
    found: list[dict] = []
    for msg in task_data.get("messages") or []:
        if not isinstance(msg, dict):
            continue
        if msg.get("type") != "say" or msg.get("say") != "context_hub_submit_kpi_result":
            continue
        raw = msg.get("text") or msg.get("content") or ""
        if not isinstance(raw, str) or not raw.strip():
            continue
        try:
            obj = json.loads(raw)
        except ValueError:
            continue
        if isinstance(obj, dict) and obj.get("type") == "context_hub_submit_kpi_result":
            found.append(obj)
    return found


def _wait_phase(task_id: str, instance_id: str, phase: str) -> dict | None:
    try:
        return wait_for_task(
            task_id,
            poll_interval=3.0,
            max_wait=TASK_MAX_WAIT,
            terminal_on_any_ask=False,
        )
    except TimeoutError as e:
        logger.warning("[warn ] %s (%s): %s", instance_id, phase, e)
    except Exception as e:
        logger.warning("[warn ] %s (%s): wait_for_task error: %s", instance_id, phase, e)
    return None


def learn_one(
    task: dict,
    rerun: bool = False,
    *,
    engine_id: str | None = None,
) -> bool:
    """Run the learn workflow for one benchmark example. Returns True on success."""
    instance_id = task["instance_id"]
    instruction = task["instruction"]
    db_id = task["db_id"]
    external_knowledge = task.get("external_knowledge")

    gold_path = _gold_sql_path(instance_id)
    if not gold_path.is_file():
        logger.warning(
            "[skip ] %s: no gold SQL at %s", instance_id, gold_path,
        )
        return False

    if _is_done(instance_id, db_id):
        if rerun:
            marker = _marker_path(instance_id, db_id)
            try:
                marker.unlink()
                logger.info("[rerun] %s: removed learn marker %s", instance_id, marker)
            except OSError as e:
                logger.warning("[warn ] %s: failed to delete marker: %s", instance_id, e)
        else:
            logger.info("[skip ] %s already learned (kpi submitted)", instance_id)
            return True

    try:
        gold_sql = gold_path.read_text(encoding="utf-8")
    except OSError as e:
        logger.error("[fail ] %s: cannot read gold SQL: %s", instance_id, e)
        return False

    logger.info("=== Learning %s (db_id=%s, engine=%s) ===",
                instance_id, db_id, engine_id or "(default)")
    task_id = str(uuid.uuid4())

    try:
        matching = select_databases_by_snowflake_database(
            snowflake_database=db_id,
            enable_matching=False,
            disable_others=False,
        )
    except Exception as e:
        logger.error(
            "[fail ] %s: failed to resolve snowflake source for db_id=%s: %s",
            instance_id, db_id, e,
        )
        return False

    if not matching:
        logger.error(
            "[fail ] %s: no remote Snowflake source for db_id=%s",
            instance_id, db_id,
        )
        return False

    database_ids = [m["id"] for m in matching if isinstance(m, dict) and m.get("id")]
    if not database_ids:
        logger.error("[fail ] %s: snowflake source for db_id=%s has no id", instance_id, db_id)
        return False

    source_names = [m.get("name") for m in matching if isinstance(m, dict)]
    logger.info("[src  ] %s: using remote snowflake source %s (ids=%s)",
                instance_id, source_names, database_ids)

    reference_paths: list[str] = []
    if external_knowledge:
        doc_path = Path(DOCUMENT_PATH) / external_knowledge
        if doc_path.is_file():
            reference_paths.append(str(doc_path))
        else:
            logger.warning("[warn ] %s: external_knowledge not found at %s",
                           instance_id, doc_path)

    # Single-turn: question + reference SQL → distill Context Hub
    learn_prompt = _build_learn_prompt(instance_id, instruction, gold_sql)
    try:
        new_task(
            text=learn_prompt,
            task_id=task_id,
            reference_paths=reference_paths or None,
            database_ids=database_ids,
            engine_id=engine_id,
        )
    except Exception as e:
        logger.error("[fail ] %s: newTask failed: %s", instance_id, e)
        return False

    logger.info("[task ] %s -> taskId=%s (distill context hub)", instance_id, task_id)
    final_data = _wait_phase(task_id, instance_id, "distill")
    if final_data is None:
        try:
            final_data = get_task_data(task_id)
        except Exception as e:
            logger.error("[fail ] %s: get_task_data failed: %s", instance_id, e)
            return False

    kpi_results = _extract_kpi_submissions(final_data)
    kpi_submitted = len(kpi_results) > 0
    if not kpi_submitted:
        logger.warning(
            "[miss ] %s: no context_hub_submit_kpi_result in task messages",
            instance_id,
        )
        return False

    kpi_names = []
    for item in kpi_results:
        payload = (item.get("data") or {}).get("payload") or {}
        name = payload.get("kpi_name")
        if name:
            kpi_names.append(name)
    logger.info(
        "[kpi  ] %s: submitted %d KPI(s): %s",
        instance_id, len(kpi_results), kpi_names or "(unnamed)",
    )

    instance_out = OUTPUT_DIR / db_id / instance_id
    instance_out.mkdir(parents=True, exist_ok=True)
    marker = {
        "instance_id": instance_id,
        "db_id": db_id,
        "task_id": task_id,
        "kpi_submitted": True,
        "kpi_count": len(kpi_results),
        "kpi_names": kpi_names,
        "gold_sql": str(gold_path),
        "finished_at": datetime.datetime.now().isoformat(timespec="seconds"),
    }
    _marker_path(instance_id, db_id).write_text(
        json.dumps(marker, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    try:
        zip_path = download_task_zip(task_id, instance_out)
        logger.info("[zip  ] %s: downloaded %s", instance_id, zip_path)
    except Exception as e:
        logger.warning("[warn ] %s: download zip failed (non-fatal): %s", instance_id, e)

    return True


def _run_task_batch(
    tasks: list[dict],
    *,
    rerun: bool,
    engine_ids: list[str],
) -> tuple[int, int]:
    """Run tasks on a global queue with one fixed engine per worker.

    Each engine worker pulls the next pending task when idle, regardless of
    ``db_id``. At most one in-flight task per engine.
    """
    total = len(tasks)
    if total == 0:
        return 0, 0

    if not engine_ids:
        logger.error("no engine ids available; skipping %d task(s)", total)
        return 0, total

    workers = len(engine_ids)

    def _run_one(idx: int, task: dict, engine_id: str) -> tuple[int, str, bool]:
        instance_id = task.get("instance_id", f"<index-{idx}>")
        db_id = str(task.get("db_id") or "unknown")
        logger.info(
            "---- [%s %d/%d] %s start (engine=%s) ----",
            db_id, idx, total, instance_id, engine_id,
        )
        try:
            ok = learn_one(task, rerun=rerun, engine_id=engine_id)
        except KeyboardInterrupt:
            raise
        except Exception as e:
            logger.exception("[fail ] %s: unhandled exception: %s", instance_id, e)
            ok = False
        logger.info(
            "---- [%s %d/%d] %s done (ok=%s, engine=%s) ----",
            db_id, idx, total, instance_id, ok, engine_id,
        )
        return idx, instance_id, ok

    if workers <= 1:
        engine_id = engine_ids[0]
        n_ok = 0
        for idx, task in enumerate(tasks, 1):
            try:
                _, _, ok = _run_one(idx, task, engine_id)
            except KeyboardInterrupt:
                logger.warning("Interrupted by user")
                raise
            n_ok += int(ok)
        return n_ok, total

    logger.info(
        "Running %d learn task(s) with %d engine worker(s): %s",
        total, workers, engine_ids,
    )

    work_q: queue.Queue[tuple[int, dict] | None] = queue.Queue()
    for idx, task in enumerate(tasks, 1):
        work_q.put((idx, task))
    for _ in engine_ids:
        work_q.put(None)

    results: list[tuple[int, str, bool]] = []
    results_lock = threading.Lock()

    def _engine_worker(engine_id: str) -> None:
        while True:
            item = work_q.get()
            try:
                if item is None:
                    return
                idx, task = item
                instance_id = task.get("instance_id", f"<index-{idx}>")
                db_id = str(task.get("db_id") or "unknown")
                logger.info(
                    "[submit] %d/%d %s (db=%s) -> engine=%s",
                    idx, total, instance_id, db_id, engine_id,
                )
                result = _run_one(idx, task, engine_id)
                with results_lock:
                    results.append(result)
            finally:
                work_q.task_done()

    executor = ThreadPoolExecutor(max_workers=workers, thread_name_prefix="learn")
    futures: list[Future] = []
    try:
        for engine_id in engine_ids:
            futures.append(executor.submit(_engine_worker, engine_id))
        for fut in futures:
            fut.result()
    except KeyboardInterrupt:
        logger.warning("Interrupted by user; shutting down engine workers...")
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

    if args.instance_id:
        requested_ids = [
            tok.strip() for tok in args.instance_id.split(",") if tok.strip()
        ]
        if not requested_ids:
            logger.error("--instance_id is empty after parsing %r", args.instance_id)
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
        logger.info("Running jsonl lines %d-%d (%d task(s))",
                    start, end, len(task_configs))

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
        logger.info(
            "Filtered to %d instance(s) for db_id(s) %s (%d skipped)",
            len(task_configs), requested_dbs, before - len(task_configs),
        )

    if not args.include_without_gold:
        before = len(task_configs)
        task_configs = [
            t for t in task_configs
            if _gold_sql_path(str(t.get("instance_id"))).is_file()
        ]
        skipped = before - len(task_configs)
        if skipped:
            logger.info(
                "Filtered to %d instance(s) with gold SQL (%d skipped; use --all to include all)",
                len(task_configs), skipped,
            )

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    try:
        engines = list_available_engines()
    except Exception as e:
        logger.error("Failed to list available engines: %s", e)
        return

    engine_ids = [
        str(item["id"])
        for item in engines
        if isinstance(item, dict) and item.get("id")
    ]
    if not engine_ids:
        logger.error(
            "No available InfiniSQL engines found via GET /api/ai_byzer/available; "
            "add at least one enabled engine before running learn."
        )
        return

    engine_names = [
        str(item.get("name") or item.get("id"))
        for item in engines
        if isinstance(item, dict) and item.get("id")
    ]
    logger.info(
        "Using %d engine worker(s): %s",
        len(engine_ids),
        list(zip(engine_names, engine_ids)),
    )

    if args.group_by_db:
        db_groups = _group_tasks_by_db(task_configs)
        logger.info(
            "Task order grouped into %d db_id(s): %s",
            len(db_groups),
            [f"{db}({len(ts)})" for db, ts in db_groups],
        )
        ordered_tasks: list[dict] = []
        for _, db_tasks in db_groups:
            ordered_tasks.extend(db_tasks)
    else:
        ordered_tasks = task_configs

    n_ok, total = _run_task_batch(
        ordered_tasks,
        rerun=args.rerun,
        engine_ids=engine_ids,
    )

    logger.info("All learn tasks finished: %d/%d succeeded", n_ok, total)


if __name__ == "__main__":
    run()
