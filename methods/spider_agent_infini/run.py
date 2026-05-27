import argparse
import datetime
import json
import logging
import os
import shutil
import sys
import threading
import zipfile
from concurrent.futures import FIRST_COMPLETED, Future, ThreadPoolExecutor, wait
from pathlib import Path

from spider_agent_infini.api.database import (
    download_task_zip,
    new_task_and_wait,
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

# Serializes the InfiniSynapse "enable matching / disable others" HTTP
# calls so concurrent workers don't issue overlapping toggles. Note this
# only protects the HTTP traffic itself; it does NOT prevent cross-task
# interference when workers target different `db_id`s — the server-side
# enabled-set is global, so a later worker's toggle will overwrite an
# earlier worker's. For best results, batch tasks that share a `db_id`
# when running with `--workers > 1`.
_TOGGLE_LOCK = threading.Lock()


def config() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run end-to-end evaluation on the benchmark"
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
        help="if set, only run this single instance_id from the jsonl",
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
        help="number of tasks to run concurrently (default: 1 = sequential). "
             "Tasks are I/O-bound (HTTP + SSE), so threads parallelize well; "
             "the data-source toggle + newTask submit step is serialized "
             "internally to avoid clobbering server-side state.",
    )
    args = parser.parse_args()
    if args.workers < 1:
        parser.error(f"--workers must be >= 1 (got {args.workers})")
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


def run_one(task: dict, mode: str, rerun: bool = False) -> bool:
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

    logger.info("=== Running %s (db_id=%s) ===", instance_id, db_id)

    # 1) Toggle data sources: enable everything tied to this db_id, disable
    # others. Locked so concurrent workers don't interleave their toggles.
    with _TOGGLE_LOCK:
        try:
            matching = select_databases_by_snowflake_database(
                snowflake_database=db_id,
                enable_matching=True,
                disable_others=True,
            )
        except Exception as e:
            logger.error("[fail ] %s: failed to enable data sources for db_id=%s: %s",
                         instance_id, db_id, e)
            return False

    if not matching:
        logger.error(
            "[fail ] %s: no InfiniSynapse data sources match db_id=%s; "
            "skipping execution. Re-run `add_database_to_infini` (or check "
            "whether the upstream Snowflake share is still available).",
            instance_id, db_id,
        )
        return False

    enabled_names = [m.get("name") for m in matching if isinstance(m, dict)]
    logger.info("[src  ] %s: enabled %d source(s): %s",
                instance_id, len(enabled_names), enabled_names)

    # 2) Locate the external-knowledge document (uploaded as reference)
    reference_paths: list[str] = []
    if external_knowledge:
        doc_path = Path(DOCUMENT_PATH) / external_knowledge
        if doc_path.is_file():
            reference_paths.append(str(doc_path))
        else:
            logger.warning("[warn ] %s: external_knowledge not found at %s",
                           instance_id, doc_path)

    # 3) Submit the new task and stream events until completion
    prompt = _build_prompt(instance_id, instruction, mode)
    try:
        result = new_task_and_wait(
            text=prompt,
            reference_paths=reference_paths or None,
        )
    except Exception as e:
        logger.error("[fail ] %s: newTask failed: %s", instance_id, e)
        return False

    task_id = result.get("taskId")
    logger.info("[task ] %s -> taskId=%s", instance_id, task_id)

    # 4) Best-effort: make sure the runtime actually finished before downloading
    try:
        wait_for_task(task_id, poll_interval=3.0, max_wait=TASK_MAX_WAIT)
    except TimeoutError as e:
        logger.warning("[warn ] %s: %s", instance_id, e)
    except Exception as e:
        logger.warning("[warn ] %s: wait_for_task error: %s", instance_id, e)

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


def run():
    args = config()
    logger.info("Args: %s", args)

    with open(JSONL_PATH, "r", encoding="utf-8") as f:
        task_configs = [json.loads(line) for line in f if line.strip()]

    if args.instance_id and args.index_range:
        logger.error("--instance_id and --range are mutually exclusive")
        return

    if args.instance_id:
        task_configs = [
            t for t in task_configs if t.get("instance_id") == args.instance_id
        ]
        if not task_configs:
            logger.error("instance_id %r not found in %s",
                         args.instance_id, JSONL_PATH)
            return
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

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    SUBMISSION_DIR_CSV.mkdir(parents=True, exist_ok=True)
    SUBMISSION_DIR_SQL.mkdir(parents=True, exist_ok=True)

    total = len(task_configs)
    workers = min(args.workers, total) if total > 0 else 1

    def _run_safely(idx: int, task: dict) -> tuple[int, str, bool]:
        instance_id = task.get("instance_id", f"<index-{idx}>")
        logger.info("---- [%d/%d] %s start ----", idx, total, instance_id)
        try:
            ok = run_one(task, args.mode, rerun=args.rerun)
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
        executor = ThreadPoolExecutor(
            max_workers=workers, thread_name_prefix="task"
        )
        futures: dict[Future, tuple[int, str]] = {}
        try:
            for idx, task in enumerate(task_configs, 1):
                instance_id = task.get("instance_id", f"<index-{idx}>")
                fut = executor.submit(_run_safely, idx, task)
                futures[fut] = (idx, instance_id)

            pending = set(futures.keys())
            while pending:
                done, pending = wait(pending, return_when=FIRST_COMPLETED)
                for fut in done:
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
            for fut in futures:
                if not fut.done():
                    fut.cancel()
            executor.shutdown(wait=False, cancel_futures=True)
            raise
        else:
            executor.shutdown(wait=True)

    logger.info("All tasks finished: %d/%d succeeded", n_ok, total)


if __name__ == "__main__":
    run()
