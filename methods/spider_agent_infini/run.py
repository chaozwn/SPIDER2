"""Run end-to-end evaluation on the spider2-snow Snowflake split.

This is the Snowflake sibling of :mod:`run_lite` (which targets the
spider2-lite SQLite ``local*`` split). The two scripts share the same
overall flow — resolve the matching InfiniSynapse data source for a task,
submit a ``newTask`` scoped via ``databaseIds``, wait for completion, and
harvest deliverables into the appropriate evaluation_suite folder — but differ in:

- JSONL: ``spider2-snow/spider2-snow.jsonl`` (``db_id`` / ``instruction``).
- Data source lookup: :func:`select_databases_by_snowflake_database` matches
  the nest-admin remote source ``remote_<db_id>`` instead of
  :func:`select_databases_by_sqlite_db_id`.
- Evaluation suite: ``spider2-snow/evaluation_suite/{example_submission_folder,
  example_submission_folder_csv}``.

Both runners accept ``--mode {sql,csv,both}`` to control which deliverable(s)
the agent must produce and which file(s) count as a successful run.

Filter by Snowflake database with ``--db_id`` (comma-separated). Omit it to run
the full jsonl across all databases. Use ``--rerun`` / ``--force`` to delete
existing submissions and re-run. Concurrency equals the number of selected
InfiniSQL engines (all available by default, or a subset via ``--engine`` by
name); each task is scoped via ``databaseIds`` and ``engineId``.
"""

from __future__ import annotations

import argparse
import datetime
import json
import logging
import os
import queue
import shutil
import sys
import threading
import uuid
import zipfile
from concurrent.futures import Future, ThreadPoolExecutor
from pathlib import Path

from spider_agent_infini.api.database import (
    download_task_zip,
    list_available_engines,
    new_task,
    select_databases_by_snowflake_database,
    wait_for_task,
)
from spider_agent_infini.spider_agent_setup_infini import (
    DOCUMENT_PATH,
    JSONL_PATH,
)


#  Logger Configs {{{ #
logger = logging.getLogger("spider_agent_infini")
logger.setLevel(logging.DEBUG)

datetime_str: str = datetime.datetime.now().strftime("%Y%m%d@%H%M%S")

os.makedirs("logs", exist_ok=True)

file_handler = logging.FileHandler(os.path.join("logs", "normal-{:}.log".format(datetime_str)), encoding="utf-8")
debug_handler = logging.FileHandler(os.path.join("logs", "debug-{:}.log".format(datetime_str)), encoding="utf-8")
stdout_handler = logging.StreamHandler(sys.stdout)
sdebug_handler = logging.FileHandler(os.path.join("logs", "sdebug-{:}.log".format(datetime_str)), encoding="utf-8")

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

logger.addHandler(file_handler)
logger.addHandler(debug_handler)
logger.addHandler(stdout_handler)
logger.addHandler(sdebug_handler)
#  }}} Logger Configs #


_PROJECT_ROOT = Path(__file__).resolve().parent
# Repo layout: <repo>/methods/spider_agent_infini/run.py
_REPO_ROOT = _PROJECT_ROOT.parent.parent
_EVAL_SUITE_DIR = _REPO_ROOT / "spider2-snow" / "evaluation_suite"
# Successful runs drop deliverables directly into the evaluation_suite so that
# `python evaluate.py --result_dir example_submission_folder[_csv]` can be run
# immediately afterwards without an extra copy step.
SUBMISSION_DIR_SQL = _EVAL_SUITE_DIR / "example_submission_folder"
SUBMISSION_DIR_CSV = _EVAL_SUITE_DIR / "example_submission_folder_csv"
OUTPUT_DIR = _PROJECT_ROOT / "output"

# Hard timeout for a single InfiniSynapse task run (seconds).
TASK_MAX_WAIT = 1800.0


def config() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run end-to-end evaluation on the spider2-snow split"
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
             "Accepts a single id (e.g. 'sf_local003') or a comma-separated "
             "list (e.g. 'sf_local003,sf_local004'). Order is preserved "
             "as given on the command line.",
    )
    parser.add_argument(
        "--range",
        dest="index_range",
        type=str,
        default=None,
        help="run a 1-indexed inclusive range of lines from the jsonl, "
             "formatted as 'start,end' (e.g. '1,2' runs lines 1-2, "
             "'3,10' runs lines 3-10).",
    )
    parser.add_argument(
        "--db_id",
        type=str,
        default=None,
        help="only run tasks for the given db_id(s), comma-separated "
             "(e.g. 'AIRLINES,PATENTS'). Can be combined with --instance_id "
             "or --range.",
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
        "--engine",
        type=str,
        default=None,
        help="only use the given InfiniSQL engine(s) by name, comma-separated "
             "(e.g. 'my-engine,other-engine'). Omit to use all available engines.",
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


def _resolve_engine_ids(
    engines: list[dict],
    engine_spec: str | None,
) -> list[str]:
    """Return engine ids to use as workers.

    If *engine_spec* is None, use all available engines. Otherwise
    *engine_spec* is a comma-separated list of engine **names** to select.
    """
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

    by_name: dict[str, str] = {}
    for item in available:
        name = str(item.get("name") or "")
        if name:
            by_name[name] = str(item["id"])

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


def _required_kinds(mode: str) -> tuple[str, ...]:
    """Return the deliverable kinds required by the given submission mode."""
    if mode == "both":
        return ("csv", "sql")
    return (mode,)


def _is_done(instance_id: str, mode: str) -> bool:
    checks = {
        "csv": SUBMISSION_DIR_CSV / f"{instance_id}.csv",
        "sql": SUBMISSION_DIR_SQL / f"{instance_id}.sql",
    }
    return all(checks[kind].exists() for kind in _required_kinds(mode))


def _clear_submissions(instance_id: str) -> list[Path]:
    """Remove any existing .sql/.csv submission files for this instance.

    Returns the list of paths that were actually deleted (useful for logging).
    """
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


def _find_first(root: Path, name: str) -> Path | None:
    for cur, _dirs, files in os.walk(root):
        if name in files:
            return Path(cur) / name
    return None


_ANSWER_SHAPE_SECTION = """<answer_shape>
The output shape MUST literally match what the question asks for. Read the
question carefully and follow these mappings:

- "How many ...", "What is the count/number of ..." → return **a single scalar
  count** (one row, one column). Do NOT return the underlying detail rows.
- "Which / List / What are the ... (top N / all ...)" → return the requested
  detail rows, only the columns the question asks about.
- "What is the average / total / max / min ..." → return that single aggregate
  value, not the per-row breakdown.
- "For each X, ..." / "... by X" / "... per X" → return one row per X, grouped
  accordingly.

Other strict rules on shape:
- Do NOT add extra columns "for context" that the question did not ask for.
- Do NOT include intermediate detail rows alongside the aggregate when only the
  aggregate was requested.
- A metric used to compute a requested rank, quintile, bucket, top-percent
  selection, or comparison is part of what the question asks for. Include that
  original metric in the final CSV unless the user explicitly asks for only the
  label or only the selected entity.
- Column names should reflect what the question is asking (e.g. a count column
  for "how many" questions). Use snake_case.
- If the question implies an ordering (e.g. "top N", "earliest", "largest"),
  apply the corresponding `ORDER BY` (and `LIMIT` where applicable).
</answer_shape>"""


def _build_prompt(instance_id: str, instruction: str, mode: str) -> str:
    needs_csv = mode in ("csv", "both")
    needs_sql = mode in ("sql", "both")

    if mode == "both":
        intro = (
            "You are a Data Analysis Agent. Solve the following business "
            "question end-to-end: first explore and analyze the data with "
            "**Infinity SQL**, then deliver the final answer as a CSV file "
            "and an equivalent **Snowflake SQL** script."
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
            "the final answer as a **Snowflake SQL** script that reproduces "
            "it."
        )

    objective_items: list[str] = []
    if needs_csv:
        objective_items.append(f"`{instance_id}.csv` — the final result table.")
    if needs_sql:
        if needs_csv:
            objective_items.append(
                f"`{instance_id}.sql` — a single Snowflake SQL script whose "
                f"final `SELECT`, when executed against Snowflake, reproduces "
                f"**exactly** the same result set (same columns, same rows, "
                f"same order) as `{instance_id}.csv`."
            )
        else:
            objective_items.append(
                f"`{instance_id}.sql` — a single Snowflake SQL script whose "
                f"final `SELECT`, when executed against Snowflake, returns "
                f"**exactly** the result that answers the question (same "
                f"columns, same rows, same order)."
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
            "You MUST produce the Snowflake SQL only AFTER the Infinity-SQL "
            "analysis is complete and the CSV is verified."
        )
        rule_lines.append(
            "The Snowflake script must contain exactly ONE final answer "
            "`SELECT` — the one that produces the CSV. Do NOT leave "
            "alternative \"or you could run this instead\" `SELECT`s (even "
            "commented out) that change the output shape."
        )
    elif needs_sql:
        rule_lines.append(
            "You MUST produce the Snowflake SQL only AFTER the Infinity-SQL "
            "analysis has confirmed the correct answer."
        )
        rule_lines.append(
            "The Snowflake script must contain exactly ONE final answer "
            "`SELECT` — the one that returns the answer. Do NOT leave "
            "alternative \"or you could run this instead\" `SELECT`s (even "
            "commented out) that change the output shape."
        )
    if needs_sql:
        rule_lines.append(
            "Prefer fully-qualified table names in the Snowflake SQL "
            "(`database.schema.table`)."
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
            "Before finalizing, do a self-check: run the Snowflake `SELECT` "
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


def run_one(
    task: dict,
    mode: str,
    rerun: bool = False,
    *,
    engine_id: str | None = None,
) -> bool:
    """Run a single benchmark example end-to-end. Returns True on success."""
    instance_id = task["instance_id"]
    instruction = task["instruction"]
    db_id = task["db_id"]
    external_knowledge = task.get("external_knowledge")

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

    logger.info(
        "=== Running %s (db_id=%s, engine=%s) ===",
        instance_id, db_id, engine_id or "(default)",
    )

    prompt = _build_prompt(instance_id, instruction, mode)
    task_id = str(uuid.uuid4())

    # 1) Resolve this db_id's Snowflake source id (no global enable/disable
    # toggle) and submit the newTask scoped to it via `databaseIds`.
    try:
        matching = select_databases_by_snowflake_database(
            snowflake_database=db_id,
            enable_matching=False,
            disable_others=False,
        )
    except Exception as e:
        logger.error("[fail ] %s: failed to resolve snowflake source for db_id=%s: %s",
                     instance_id, db_id, e)
        return False

    if not matching:
        logger.error(
            "[fail ] %s: no InfiniSynapse remote Snowflake source matches db_id=%s; "
            "skipping execution. Re-run `add_remote_database_to_infini` (or check "
            "whether the upstream Snowflake share is still available).",
            instance_id, db_id,
        )
        return False

    database_ids = [m["id"] for m in matching if isinstance(m, dict) and m.get("id")]
    if not database_ids:
        logger.error(
            "[fail ] %s: snowflake source for db_id=%s has no id",
            instance_id, db_id,
        )
        return False

    source_names = [m.get("name") for m in matching if isinstance(m, dict)]
    logger.info("[src  ] %s: using remote snowflake source %s (ids=%s)",
                instance_id, source_names, database_ids)

    # 2) Locate the external-knowledge document (uploaded as reference)
    reference_paths: list[str] = []
    if external_knowledge:
        doc_path = Path(DOCUMENT_PATH) / external_knowledge
        if doc_path.is_file():
            reference_paths.append(str(doc_path))
        else:
            logger.warning("[warn ] %s: external_knowledge not found at %s",
                           instance_id, doc_path)

    # 3) Submit the new task scoped to the resolved data source
    try:
        new_task(
            text=prompt,
            task_id=task_id,
            reference_paths=reference_paths or None,
            database_ids=database_ids,
            engine_id=engine_id,
        )
    except Exception as e:
        logger.error("[fail ] %s: newTask failed: %s", instance_id, e)
        return False

    logger.info("[task ] %s -> taskId=%s (submitted)", instance_id, task_id)

    # 4) Wait until the runtime actually finished before downloading
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

    # 5) Download workspace zip and extract
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

    # 6) Locate the deliverables anywhere within the extracted workspace.
    # We always try to harvest both `<id>.csv` and `<id>.sql` if present —
    # the agent may volunteer a side product even in single-mode runs.
    # `mode` decides which one(s) are REQUIRED for the run to count as
    # successful (see `_required_kinds`).
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


def _run_task_batch(
    tasks: list[dict],
    *,
    mode: str,
    rerun: bool,
    engine_ids: list[str],
) -> tuple[int, int]:
    """Run tasks on a global queue with one fixed engine per worker."""
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
            ok = run_one(task, mode, rerun=rerun, engine_id=engine_id)
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
        "Running %d task(s) with %d engine worker(s): %s",
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

    executor = ThreadPoolExecutor(max_workers=workers, thread_name_prefix="task")
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


def run():
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
            logger.error(
                "instance_id(s) %s not found in %s",
                missing, JSONL_PATH,
            )
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
        # 1-indexed inclusive -> 0-indexed slice
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

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    SUBMISSION_DIR_CSV.mkdir(parents=True, exist_ok=True)
    SUBMISSION_DIR_SQL.mkdir(parents=True, exist_ok=True)

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
        logger.error(
            "No available InfiniSQL engines found via GET /api/ai_byzer/available; "
            "add at least one enabled engine before running."
        )
        return

    id_to_name = {
        str(item["id"]): str(item.get("name") or item["id"])
        for item in engines
        if isinstance(item, dict) and item.get("id")
    }
    logger.info(
        "Using %d engine worker(s): %s",
        len(engine_ids),
        [(id_to_name.get(eid, eid), eid) for eid in engine_ids],
    )

    n_ok, total = _run_task_batch(
        task_configs,
        mode=args.mode,
        rerun=args.rerun,
        engine_ids=engine_ids,
    )

    logger.info("All tasks finished: %d/%d succeeded", n_ok, total)


if __name__ == "__main__":
    run()
