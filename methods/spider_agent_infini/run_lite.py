"""Run end-to-end evaluation on the spider2-lite SQLite (`local*`) split.

This is the SQLite sibling of :mod:`run` (which targets the spider2-snow
Snowflake split). The two scripts share the same overall flow — toggle the
matching InfiniSynapse data source for a task, submit a `newTask` via the
InfiniSynapse API, wait for completion, and harvest the deliverables into
the appropriate evaluation_suite folder — but differ in:

- JSONL: ``spider2-lite/spider2-lite.jsonl`` (uses ``db`` and ``question``
  field names; this script normalizes them to ``db_id`` / ``instruction``).
- Filtering: only ``instance_id`` starting with ``local`` is run; bigquery
  / snowflake instances inside the lite split are skipped (use ``run.py``
  for those).
- Data source toggle: :func:`select_databases_by_sqlite_db_id` instead of
  :func:`select_databases_by_snowflake_database`.
- Evaluation suite: ``spider2-lite/evaluation_suite/{example_submission_folder,
  example_submission_folder_csv}``.

We import :func:`run.run_one`-related helpers wherever possible. The bits
that differ (data-source toggle, prompt copy, eval-suite paths) live here.
"""

from __future__ import annotations

import argparse
import datetime
import json
import logging
import os
import shutil
import sys
import uuid
import zipfile
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from spider_agent_infini.api.database import (
    download_task_zip,
    new_task,
    select_databases_by_sqlite_db_id,
    wait_for_task,
)
from spider_agent_infini.spider_agent_setup_infini import (
    LITE_DOCUMENT_PATH,
    LITE_JSONL_PATH,
    LOCAL_MAP_PATH,
)

# Reuse the prompt-shape boilerplate, range parser and shared knobs from the
# Snowflake runner so the two stay in lock-step.
from run import (
    TASK_MAX_WAIT,
    _ANSWER_SHAPE_SECTION,
    _find_first,
    _parse_range,
    _required_kinds,
)


#  Logger Configs {{{ #
logger = logging.getLogger("spider_agent_infini")
logger.setLevel(logging.DEBUG)

datetime_str: str = datetime.datetime.now().strftime("%Y%m%d@%H%M%S")

os.makedirs("logs", exist_ok=True)

file_handler = logging.FileHandler(os.path.join("logs", "lite-normal-{:}.log".format(datetime_str)), encoding="utf-8")
debug_handler = logging.FileHandler(os.path.join("logs", "lite-debug-{:}.log".format(datetime_str)), encoding="utf-8")
stdout_handler = logging.StreamHandler(sys.stdout)
sdebug_handler = logging.FileHandler(os.path.join("logs", "lite-sdebug-{:}.log".format(datetime_str)), encoding="utf-8")

file_handler.setLevel(logging.INFO)
debug_handler.setLevel(logging.DEBUG)
stdout_handler.setLevel(logging.INFO)
sdebug_handler.setLevel(logging.DEBUG)

formatter = logging.Formatter(
    fmt="\x1b[1;33m[%(asctime)s \x1b[31m%(levelname)s \x1b[32m%(module)s/%(lineno)d-%(processName)s/%(threadName)s\x1b[1;33m] \x1b[0m%(message)s")
file_handler.setFormatter(formatter)
debug_handler.setFormatter(formatter)
stdout_handler.setFormatter(formatter)
sdebug_handler.setFormatter(formatter)

stdout_handler.addFilter(logging.Filter("spider_agent_infini"))
sdebug_handler.addFilter(logging.Filter("spider_agent_infini"))

# Avoid duplicating handlers if `run.py` was already imported in the same
# process (it attaches its own handlers to the same logger).
if not any(isinstance(h, logging.FileHandler) and "lite-normal" in h.baseFilename
           for h in logger.handlers):
    logger.addHandler(file_handler)
    logger.addHandler(debug_handler)
    logger.addHandler(stdout_handler)
    logger.addHandler(sdebug_handler)
#  }}} Logger Configs #


_PROJECT_ROOT = Path(__file__).resolve().parent
# Repo layout: <repo>/methods/spider_agent_infini/run_lite.py
_REPO_ROOT = _PROJECT_ROOT.parent.parent
_EVAL_SUITE_DIR = _REPO_ROOT / "spider2-lite" / "evaluation_suite"
SUBMISSION_DIR_SQL = _EVAL_SUITE_DIR / "example_submission_folder"
SUBMISSION_DIR_CSV = _EVAL_SUITE_DIR / "example_submission_folder_csv"
OUTPUT_DIR = _PROJECT_ROOT / "output_lite"


def config() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run end-to-end evaluation on the spider2-lite SQLite split"
    )
    parser.add_argument(
        "--mode",
        type=str,
        choices=["sql", "csv", "both"],
        default="csv",
        help="submission mode: 'sql' to submit a .sql file, "
             "'csv' to submit a .csv result file, "
             "'both' to require both .sql and .csv deliverables",
    )
    parser.add_argument(
        "--instance_id",
        type=str,
        default=None,
        help="if set, only run the given instance_id(s) from the jsonl. "
             "Accepts a single id (e.g. 'local002') or a comma-separated "
             "list (e.g. 'local002,local003,local007'). Order is preserved "
             "as given on the command line.",
    )
    parser.add_argument(
        "--range",
        dest="index_range",
        type=str,
        default=None,
        help="run a 1-indexed inclusive range of lines from the (filtered) "
             "jsonl, formatted as 'start,end' (e.g. '1,2' runs lines 1-2). "
             "Indexing is over the local* subset only.",
    )
    parser.add_argument(
        "--rerun",
        "--force",
        dest="rerun",
        action="store_true",
        help="force re-run even if the submission already exists; "
             "existing .sql/.csv submissions for the targeted instance(s) "
             "will be deleted before the run.",
    )
    parser.add_argument(
        "--workers",
        "-j",
        type=int,
        default=1,
        help="number of tasks to run concurrently (default: 1 = sequential).",
    )
    args = parser.parse_args()
    if args.workers < 1:
        parser.error(f"--workers must be >= 1 (got {args.workers})")
    return args


def _is_done(instance_id: str, mode: str) -> bool:
    checks = {
        "csv": SUBMISSION_DIR_CSV / f"{instance_id}.csv",
        "sql": SUBMISSION_DIR_SQL / f"{instance_id}.sql",
    }
    return all(checks[kind].exists() for kind in _required_kinds(mode))


def _clear_submissions(instance_id: str) -> list[Path]:
    removed: list[Path] = []
    for path in (
        SUBMISSION_DIR_CSV / f"{instance_id}.csv",
        SUBMISSION_DIR_SQL / f"{instance_id}.sql",
    ):
        if path.exists():
            try:
                path.unlink()
                removed.append(path)
            except OSError as e:
                logger.warning("[warn ] %s: failed to delete %s: %s",
                               instance_id, path, e)
    return removed


def _extract_zip(zip_path: str | os.PathLike, dest: Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zip_path) as zf:
        zf.extractall(dest)


def _build_prompt(instance_id: str, instruction: str, mode: str) -> str:
    """Build the agent prompt for a sqlite/local* task.

    Same structure as :func:`run._build_prompt`, but the deliverable is
    described as **SQLite SQL** — the spider2-lite evaluation suite executes
    the submitted ``.sql`` against the local SQLite databases shipped with
    the benchmark, so we explicitly steer dialect-sensitive choices toward
    SQLite (no fully-qualified ``database.schema.table`` requirement, etc.).
    """
    needs_csv = mode in ("csv", "both")
    needs_sql = mode in ("sql", "both")

    if mode == "both":
        intro = (
            "You are a Data Analysis Agent. Solve the following business "
            "question end-to-end: first explore and analyze the data with "
            "**Infinity SQL**, then deliver the final answer as a CSV file "
            "and an equivalent **SQLite SQL** script."
        )
    elif mode == "csv":
        intro = (
            "You are a Data Analysis Agent. Solve the following business "
            "question end-to-end: explore and analyze the data with "
            "**Infinity SQL**, then deliver the final answer as a CSV file."
        )
    else:  # sql
        intro = (
            "You are a Data Analysis Agent. Solve the following business "
            "question end-to-end: first explore and analyze the data with "
            "**Infinity SQL** to determine the correct answer, then deliver "
            "the final answer as a **SQLite SQL** script that reproduces it."
        )

    objective_items: list[str] = []
    if needs_csv:
        objective_items.append(f"`{instance_id}.csv` — the final result table.")
    if needs_sql:
        if needs_csv:
            objective_items.append(
                f"`{instance_id}.sql` — a single SQLite SQL script whose "
                f"final `SELECT`, when executed against the spider2-lite "
                f"SQLite database, reproduces **exactly** the same result "
                f"set (same columns, same rows, same order) as "
                f"`{instance_id}.csv`."
            )
        else:
            objective_items.append(
                f"`{instance_id}.sql` — a single SQLite SQL script whose "
                f"final `SELECT`, when executed against the spider2-lite "
                f"SQLite database, returns **exactly** the result that "
                f"answers the question (same columns, same rows, same order)."
            )
    if len(objective_items) == 1:
        deliverable_lead = "one deliverable that **strictly** answers"
    else:
        deliverable_lead = "two deliverables that **strictly** answer"
    objective_body = "\n".join(
        f"{i}. {item}" for i, item in enumerate(objective_items, 1)
    )
    objective = (
        "<objective>\n"
        f"Produce {deliverable_lead} the user's question — no more, no less:\n"
        f"{objective_body}\n"
        "</objective>"
    )

    rule_lines: list[str] = [
        "You MUST use Infinity SQL (via `execute_infinity_sql`) to derive and "
        "validate the answer. Do NOT fabricate results.",
        "Do NOT use any machine-learning methods/functions in Infinity SQL "
        "(no model training/inference, clustering, regression, forecasting, "
        "or other ML-based operators). Use only plain SQL "
        "(filters, joins, aggregations, window functions, etc.).",
    ]
    if needs_sql and needs_csv:
        rule_lines.append(
            "You MUST produce the SQLite SQL only AFTER the Infinity-SQL "
            "analysis is complete and the CSV is verified."
        )
        rule_lines.append(
            "The SQLite script must contain exactly ONE final answer "
            "`SELECT` — the one that produces the CSV. Do NOT leave "
            "alternative \"or you could run this instead\" `SELECT`s (even "
            "commented out) that change the output shape."
        )
    elif needs_sql:
        rule_lines.append(
            "You MUST produce the SQLite SQL only AFTER the Infinity-SQL "
            "analysis has confirmed the correct answer."
        )
        rule_lines.append(
            "The SQLite script must contain exactly ONE final answer "
            "`SELECT` — the one that returns the answer. Do NOT leave "
            "alternative \"or you could run this instead\" `SELECT`s (even "
            "commented out) that change the output shape."
        )
    if needs_sql:
        rule_lines.append(
            "Use plain SQLite-dialect SQL (no `database.schema.` prefixes; "
            "use bare table names as they appear in the SQLite database)."
        )
        rule_lines.append(
            "If the question is ambiguous, pick the most reasonable "
            "interpretation and state your assumption inside "
            f"`{instance_id}.sql` as a leading SQL comment."
        )
    else:
        rule_lines.append(
            "If the question is ambiguous, pick the most reasonable "
            "interpretation and clearly state your assumption in your final "
            "message (keep the CSV itself pure data — no comment rows)."
        )
    if needs_sql and needs_csv:
        rule_lines.append(
            "Before finalizing, do a self-check: run the SQLite `SELECT` "
            "mentally against the CSV — number of rows, columns, and "
            "ordering must match exactly."
        )
        completion_clause = (
            "both deliverables exist, are mutually consistent, and literally "
            "answer the question"
        )
    elif needs_sql:
        completion_clause = (
            f"`{instance_id}.sql` exists and its final `SELECT` literally "
            "answers the question"
        )
    else:
        completion_clause = (
            f"`{instance_id}.csv` exists and literally answers the question"
        )
    rule_lines.append(
        f"Never stop early: keep iterating until {completion_clause}."
    )
    rules_section = (
        "<rules>\n" + "\n".join(f"- {r}" for r in rule_lines) + "\n</rules>"
    )

    return f"""
{intro}

{objective}

{_ANSWER_SHAPE_SECTION}

{rules_section}

<question>
{instruction}
</question>
"""


def _load_local_map(local_map_path: str = LOCAL_MAP_PATH) -> dict[str, str]:
    """Load ``local-map.jsonl`` into ``{instance_id: db_id}``.

    This is the AUTHORITATIVE mapping shared between setup and runtime:
    setup registers exactly the sqlite db_ids that appear as values here,
    and run_lite picks tasks (and their db_id) by joining on the keys here.
    The ``db`` field in spider2-lite.jsonl is treated as a hint only — if
    it disagrees with local-map, local-map wins, and we log a warning so
    the drift is visible.
    """
    mapping: dict[str, str] = {}
    with open(local_map_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            obj = json.loads(line)
            if isinstance(obj, dict):
                for k, v in obj.items():
                    if k and v:
                        mapping[str(k)] = str(v)
    return mapping


def _normalize_lite_task(task: dict, local_map: dict[str, str]) -> dict:
    """Map spider2-lite field names onto the spider2-snow shape this script
    expects internally (``db_id`` / ``instruction``).

    For ``local*`` tasks, ``db_id`` is taken from ``local-map.jsonl`` (the
    authoritative mapping that setup also uses); the ``db`` field in the
    jsonl is just a hint. A mismatch is logged so the drift is visible.
    """
    out = dict(task)
    iid = str(out.get("instance_id", ""))
    if "instruction" not in out and "question" in out:
        out["instruction"] = out["question"]

    mapped = local_map.get(iid)
    raw_db = out.get("db")
    if mapped is not None:
        if raw_db is not None and raw_db != mapped:
            logger.warning(
                "[map  ] %s: spider2-lite.jsonl db=%r differs from "
                "local-map.jsonl db_id=%r; using local-map (authoritative).",
                iid, raw_db, mapped,
            )
        out["db_id"] = mapped
    elif "db_id" not in out and raw_db is not None:
        out["db_id"] = raw_db
    return out


def run_one(
    task: dict,
    mode: str,
    rerun: bool = False,
    local_map: dict[str, str] | None = None,
) -> bool:
    """Run a single spider2-lite ``local*`` task end-to-end. Returns True on
    success.

    ``local_map`` is the authoritative ``{instance_id: db_id}`` mapping
    loaded from ``local-map.jsonl``. When omitted (e.g. callers from a
    REPL), it is loaded once from disk; the runner ``run()`` always passes
    the pre-loaded map to avoid re-reading per task.
    """
    if local_map is None:
        local_map = _load_local_map()
    task = _normalize_lite_task(task, local_map)
    instance_id = task["instance_id"]
    instruction = task["instruction"]
    db_id = task.get("db_id")
    external_knowledge = task.get("external_knowledge")

    # We trust callers (`run()`) to filter via `local-map.jsonl`; the only
    # way to reach here without a db_id is calling `run_one` directly with
    # an instance_id that's not in local-map. Bail loudly in that case
    # rather than silently sending the task to a wrong sqlite source.
    if not db_id:
        logger.error(
            "[fail ] %s: no db_id resolved (not present in %s); skipping.",
            instance_id, LOCAL_MAP_PATH,
        )
        return False

    if _is_done(instance_id, mode):
        if rerun:
            removed = _clear_submissions(instance_id)
            if removed:
                logger.info(
                    "[rerun] %s: removed %d existing submission(s): %s",
                    instance_id, len(removed), [str(p) for p in removed],
                )
        else:
            kinds = ", ".join(f".{k}" for k in _required_kinds(mode))
            logger.info("[skip ] %s already has %s submission(s)", instance_id, kinds)
            return True

    logger.info("=== Running %s (db_id=%s) ===", instance_id, db_id)

    # Locate the external-knowledge document (uploaded as reference). Done
    # before the lock so the critical section stays as short as possible.
    reference_paths: list[str] = []
    if external_knowledge:
        doc_path = Path(LITE_DOCUMENT_PATH) / external_knowledge
        if doc_path.is_file():
            reference_paths.append(str(doc_path))
        else:
            logger.warning("[warn ] %s: external_knowledge not found at %s",
                           instance_id, doc_path)

    prompt = _build_prompt(instance_id, instruction, mode)
    task_id = str(uuid.uuid4())

    # 1) Resolve this db_id's SQLite source id (no global enable/disable
    # toggle) and submit the newTask scoped to it via `databaseIds`. Because
    # the source is selected per-task on the server, workers run fully in
    # parallel without a shared lock — concurrent tasks can target different
    # databases at the same time.
    try:
        matching = select_databases_by_sqlite_db_id(
            db_id=db_id,
            enable_matching=False,
            disable_others=False,
        )
    except Exception as e:
        logger.error("[fail ] %s: failed to resolve sqlite source for db_id=%s: %s",
                     instance_id, db_id, e)
        return False

    if not matching:
        logger.error(
            "[fail ] %s: no InfiniSynapse SQLite source matches db_id=%s; "
            "skipping execution. Re-run `add_sqlite_database_to_infini` "
            "(see spider_agent_setup_infini.py) to register it.",
            instance_id, db_id,
        )
        return False

    database_ids = [m["id"] for m in matching if isinstance(m, dict) and m.get("id")]
    if not database_ids:
        logger.error(
            "[fail ] %s: sqlite source(s) for db_id=%s have no usable id: %s",
            instance_id, db_id, matching,
        )
        return False

    source_names = [m.get("name") for m in matching if isinstance(m, dict)]
    logger.info("[src  ] %s: using %d sqlite source(s): %s (ids=%s)",
                instance_id, len(database_ids), source_names, database_ids)

    try:
        new_task(
            text=prompt,
            task_id=task_id,
            reference_paths=reference_paths or None,
            database_ids=database_ids,
        )
    except Exception as e:
        logger.error("[fail ] %s: newTask failed: %s", instance_id, e)
        return False

    logger.info("[task ] %s -> taskId=%s (submitted)", instance_id, task_id)

    # 2) Wait until the runtime actually finished before downloading
    try:
        wait_for_task(
            task_id,
            poll_interval=3.0,
            max_wait=TASK_MAX_WAIT,
            terminal_on_any_ask=False,
            timeout=30.0,
        )
    except TimeoutError as e:
        logger.error("[fail ] %s: task wait timed out: %s", instance_id, e)
        return False
    except Exception as e:
        logger.error("[fail ] %s: wait_for_task error: %s", instance_id, e)
        return False

    # 3) Download workspace zip and extract
    task_output_dir = OUTPUT_DIR / instance_id
    task_output_dir.mkdir(parents=True, exist_ok=True)
    try:
        zip_path = download_task_zip(task_id, task_output_dir)
        logger.info("[zip  ] %s: downloaded %s", instance_id, zip_path)
    except Exception as e:
        logger.error("[fail ] %s: download zip failed: %s", instance_id, e)
        return False

    extract_dir = task_output_dir / "workspace"
    if extract_dir.exists():
        shutil.rmtree(extract_dir)
    try:
        _extract_zip(zip_path, extract_dir)
    except Exception as e:
        logger.error("[fail ] %s: unzip failed: %s", instance_id, e)
        return False

    # 4) Locate the deliverables anywhere within the extracted workspace.
    deliverables = [
        ("csv", f"{instance_id}.csv", SUBMISSION_DIR_CSV),
        ("sql", f"{instance_id}.sql", SUBMISSION_DIR_SQL),
    ]

    saved: dict[str, Path] = {}
    for kind, name, dst_dir in deliverables:
        src = _find_first(extract_dir, name)
        if src is None:
            continue
        dst_dir.mkdir(parents=True, exist_ok=True)
        dst = dst_dir / name
        shutil.copyfile(src, dst)
        saved[kind] = dst
        logger.info("[%s  ] %s: saved -> %s", kind, instance_id, dst)

    missing = [kind for kind in _required_kinds(mode) if kind not in saved]
    if missing:
        required_names = [f"{instance_id}.{kind}" for kind in missing]
        logger.warning(
            "[miss ] %s: required deliverable(s) %s not found in task workspace",
            instance_id, required_names,
        )
        return False
    return True


def run():
    args = config()
    logger.info("Args: %s", args)

    # spider2-lite.jsonl is the authoritative source for the task list:
    # it carries the question text + external_knowledge per instance. We
    # filter to instances whose `instance_id` starts with `local` (the
    # SQLite split inside spider2-lite). bq* / sf_* / dbt tasks share the
    # same jsonl but are out of scope for this runner.
    with open(LITE_JSONL_PATH, "r", encoding="utf-8") as f:
        all_tasks = [json.loads(line) for line in f if line.strip()]

    task_configs = [
        t for t in all_tasks
        if str(t.get("instance_id", "")).startswith("local")
    ]
    skipped = len(all_tasks) - len(task_configs)
    logger.info(
        "Loaded %d local* task(s) from %s (skipped %d non-local entries)",
        len(task_configs), LITE_JSONL_PATH, skipped,
    )

    # local-map.jsonl is loaded only for db_id resolution / cross-check
    # against `task["db"]`. If they disagree, we trust local-map (since
    # setup registered sqlite sources from it) and emit a WARNING so the
    # drift is visible. Tasks present in spider2-lite.jsonl but missing
    # from local-map fall back to `task["db"]`.
    local_map = _load_local_map()
    logger.info(
        "Loaded %d entries from %s (used for db_id resolution)",
        len(local_map), LOCAL_MAP_PATH,
    )

    jsonl_local_ids = {str(t.get("instance_id", "")) for t in task_configs}
    map_only = sorted(set(local_map) - jsonl_local_ids)
    jsonl_only = sorted(jsonl_local_ids - set(local_map))
    if map_only:
        logger.warning(
            "[map  ] %d local-map entries missing in %s: %s",
            len(map_only), LITE_JSONL_PATH, map_only[:10],
        )
    if jsonl_only:
        logger.warning(
            "[map  ] %d local* tasks in %s missing from local-map.jsonl "
            "(will fall back to task['db']): %s",
            len(jsonl_only), LITE_JSONL_PATH, jsonl_only[:10],
        )

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
            logger.error(
                "instance_id(s) %s not found among local* tasks in %s",
                missing, LITE_JSONL_PATH,
            )
            return

        task_configs = [by_id[iid] for iid in unique_requested]
        logger.info(
            "Running %d explicitly-requested local* instance(s): %s",
            len(task_configs), unique_requested,
        )
    elif args.index_range:
        try:
            start, end = _parse_range(args.index_range, len(task_configs))
        except ValueError as e:
            logger.error("%s", e)
            return
        task_configs = task_configs[start - 1:end]
        logger.info("Running local* lines %d-%d (%d task(s))",
                    start, end, len(task_configs))

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    SUBMISSION_DIR_CSV.mkdir(parents=True, exist_ok=True)
    SUBMISSION_DIR_SQL.mkdir(parents=True, exist_ok=True)

    total = len(task_configs)
    workers = min(args.workers, total) if total > 0 else 1

    def _run_safely(idx: int, task: dict) -> tuple[int, str, bool]:
        instance_id = task.get("instance_id", f"<index-{idx}>")
        logger.info("---- [%d/%d] %s start ----", idx, total, instance_id)
        try:
            ok = run_one(
                task, args.mode, rerun=args.rerun, local_map=local_map,
            )
        except KeyboardInterrupt:
            raise
        except Exception as e:
            logger.exception("[fail ] %s: unhandled exception: %s", instance_id, e)
            ok = False
        logger.info("---- [%d/%d] %s done (ok=%s) ----", idx, total, instance_id, ok)
        return idx, instance_id, ok

    n_ok = 0
    if workers <= 1:
        for idx, task in enumerate(task_configs, 1):
            try:
                _, _, ok = _run_safely(idx, task)
            except KeyboardInterrupt:
                logger.warning("Interrupted by user")
                raise
            n_ok += int(ok)
    else:
        logger.info("Running %d task(s) with %d worker(s)", total, workers)
        # Hand every task to the pool up front; the executor runs at most
        # `workers` of them concurrently and queues the rest. Each worker
        # runs a task end-to-end (toggle source, submit, wait, download,
        # copy CSV) fully in parallel — no shared lock between workers.
        executor = ThreadPoolExecutor(
            max_workers=workers, thread_name_prefix="lite"
        )
        futures = {
            executor.submit(_run_safely, idx, task): (
                idx, task.get("instance_id", f"<index-{idx}>")
            )
            for idx, task in enumerate(task_configs, 1)
        }
        try:
            for fut in as_completed(futures):
                idx, instance_id = futures[fut]
                try:
                    _, _, ok = fut.result()
                except Exception as e:
                    logger.exception(
                        "[fail ] %s: worker raised: %s", instance_id, e,
                    )
                    ok = False
                n_ok += int(ok)
        except KeyboardInterrupt:
            logger.warning(
                "Interrupted by user; cancelling pending tasks "
                "(in-flight tasks will keep running until they finish or "
                "their next blocking I/O is interrupted)..."
            )
            executor.shutdown(wait=False, cancel_futures=True)
            raise
        else:
            executor.shutdown(wait=True)

    logger.info("All tasks finished: %d/%d succeeded", n_ok, total)


if __name__ == "__main__":
    run()
