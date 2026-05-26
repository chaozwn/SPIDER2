import argparse
import datetime
import json
import logging
import os
import shutil
import sys
import zipfile
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
    fmt="\x1b[1;33m[%(asctime)s \x1b[31m%(levelname)s \x1b[32m%(module)s/%(lineno)d-%(processName)s\x1b[1;33m] \x1b[0m%(message)s")
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
SUBMISSION_DIR_SQL = _PROJECT_ROOT / "spider_agent_infini" / "example_submission_folder"
SUBMISSION_DIR_CSV = _PROJECT_ROOT / "spider_agent_infini" / "example_submission_folder_csv"
OUTPUT_DIR = _PROJECT_ROOT / "output"

# Hard timeout for a single InfiniSynapse task run (seconds).
TASK_MAX_WAIT = 1800.0


def config() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run end-to-end evaluation on the benchmark"
    )
    parser.add_argument(
        "--mode",
        type=str,
        choices=["sql", "csv"],
        default="csv",
        help="submission mode: 'sql' to submit a .sql file, "
             "'csv' to submit a .csv result file",
    )
    parser.add_argument(
        "--instance_id",
        type=str,
        default=None,
        help="if set, only run this single instance_id from the jsonl",
    )
    return parser.parse_args()


def _is_done(instance_id: str, mode: str) -> bool:
    if mode == "csv":
        return (SUBMISSION_DIR_CSV / f"{instance_id}.csv").exists()
    return (SUBMISSION_DIR_SQL / f"{instance_id}.sql").exists()


def _extract_zip(zip_path: str | os.PathLike, dest: Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zip_path) as zf:
        zf.extractall(dest)


def _find_first(root: Path, name: str) -> Path | None:
    for cur, _dirs, files in os.walk(root):
        if name in files:
            return Path(cur) / name
    return None


def _build_prompt(instance_id: str, instruction: str) -> str:
    return f"""
You are a Data Analysis Agent. Solve the following business question end-to-end:
first explore and analyze the data with **Infinity SQL**, then deliver the final
answer as a CSV file and an equivalent **Snowflake SQL** script.

<objective>
Produce two deliverables that **strictly** answer the user's question — no more,
no less:
1. `{instance_id}.csv` — the final result table.
2. `{instance_id}.sql` — a single Snowflake SQL script whose final `SELECT`,
   when executed against Snowflake, reproduces **exactly** the same result set
   (same columns, same rows, same order) as `{instance_id}.csv`.
</objective>

<answer_shape>
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
</answer_shape>

<rules>
- You MUST use Infinity SQL (via `execute_infinity_sql`) to derive and validate
  the answer. Do NOT fabricate results.
- You MUST produce the Snowflake SQL only AFTER the Infinity-SQL analysis is
  complete and the CSV is verified.
- The Snowflake script must contain exactly ONE final answer `SELECT` — the one
  that produces the CSV. Do NOT leave alternative "or you could run this
  instead" `SELECT`s (even commented out) that change the output shape.
- Prefer fully-qualified table names in the Snowflake SQL (`database.schema.table`).
- If the question is ambiguous, pick the most reasonable interpretation and
  state your assumption inside `{instance_id}.sql` as a leading SQL comment.
- Before finalizing, do a self-check: run the Snowflake `SELECT` mentally
  against the CSV — number of rows, columns, and ordering must match exactly.
- Never stop early: keep iterating until both deliverables exist, are mutually
  consistent, and literally answer the question.
</rules>

<question>
{instruction}
</question>
"""


def run_one(task: dict, mode: str) -> bool:
    """Run a single benchmark example end-to-end. Returns True on success."""
    instance_id = task["instance_id"]
    instruction = task["instruction"]
    db_id = task["db_id"]
    external_knowledge = task.get("external_knowledge")

    if _is_done(instance_id, mode):
        logger.info("[skip ] %s already has a .%s submission", instance_id, mode)
        return True

    logger.info("=== Running %s (db_id=%s) ===", instance_id, db_id)

    # 1) Toggle data sources: enable everything tied to this db_id, disable others
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
        logger.warning(
            "[warn ] %s: no InfiniSynapse data sources match db_id=%s; "
            "did `add_database_to_infini` succeed for this db?",
            instance_id, db_id,
        )

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
    prompt = _build_prompt(instance_id, instruction)
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
    # The agent is prompted to produce BOTH `<id>.csv` and `<id>.sql`, so we
    # always try to harvest both. `mode` only decides which one is REQUIRED
    # for the run to count as successful.
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

    if mode not in saved:
        # The required deliverable for this --mode is missing.
        required_name = f"{instance_id}.{mode}"
        logger.warning(
            "[miss ] %s: required deliverable %s not found in task workspace",
            instance_id, required_name,
        )
        return False
    return True


def run():
    args = config()
    logger.info("Args: %s", args)

    with open(JSONL_PATH, "r", encoding="utf-8") as f:
        task_configs = [json.loads(line) for line in f if line.strip()]

    if args.instance_id:
        task_configs = [
            t for t in task_configs if t.get("instance_id") == args.instance_id
        ]
        if not task_configs:
            logger.error("instance_id %r not found in %s",
                         args.instance_id, JSONL_PATH)
            return

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    SUBMISSION_DIR_CSV.mkdir(parents=True, exist_ok=True)
    SUBMISSION_DIR_SQL.mkdir(parents=True, exist_ok=True)

    total = len(task_configs)
    n_ok = 0
    for idx, task in enumerate(task_configs, 1):
        instance_id = task.get("instance_id", f"<index-{idx}>")
        logger.info("---- [%d/%d] %s ----", idx, total, instance_id)
        try:
            ok = run_one(task, args.mode)
        except KeyboardInterrupt:
            logger.warning("Interrupted by user during %s", instance_id)
            raise
        except Exception as e:
            logger.exception("[fail ] %s: unhandled exception: %s", instance_id, e)
            ok = False
        n_ok += int(ok)
        logger.info("---- [%d/%d] %s done (ok=%s) ----", idx, total, instance_id, ok)

    logger.info("All tasks finished: %d/%d succeeded", n_ok, total)


if __name__ == "__main__":
    run()
