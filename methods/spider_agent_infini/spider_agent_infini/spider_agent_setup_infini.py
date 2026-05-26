import json
import logging
from datetime import datetime
from pathlib import Path

logger = logging.getLogger("spider_agent_infini")

_PROJECT_ROOT = Path(__file__).resolve().parent.parent
_REPO_ROOT = _PROJECT_ROOT.parent.parent

JSONL_PATH = str(_REPO_ROOT / "spider2-snow" / "spider2-snow.jsonl")
DATABASE_PATH = str(_REPO_ROOT / "spider2-snow" / "resource" / "databases") + "/"
DOCUMENT_PATH = str(_REPO_ROOT / "spider2-snow" / "resource" / "documents")
INFINI_CREDENTIAL_PATH = str(_PROJECT_ROOT / "infini_credential.json")
SNOWFLAKE_CREDENTIAL_PATH = str(_PROJECT_ROOT / "snowflake_credential.json")
FAILURE_LOG_PATH = str(_PROJECT_ROOT / "setup_failures.log")

EXCLUDED_SCHEMAS = {"INFORMATION_SCHEMA", "PUBLIC"}


def _log_failure(message: str) -> None:
    line = f"[{datetime.now().isoformat(timespec='seconds')}] {message}"
    logger.error(message)
    with open(FAILURE_LOG_PATH, "a", encoding="utf-8") as f:
        f.write(line + "\n")


def _load_db_ids(jsonl_path: str) -> list[str]:
    seen: set[str] = set()
    ordered: list[str] = []
    with open(jsonl_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            db_id = json.loads(line).get("db_id")
            if db_id and db_id not in seen:
                seen.add(db_id)
                ordered.append(db_id)
    return ordered


def _list_snowflake_schemas(db_id: str, snowflake_credential_path: str) -> list[str]:
    import snowflake.connector

    with open(snowflake_credential_path, "r", encoding="utf-8") as f:
        sf = json.load(f)

    conn = snowflake.connector.connect(
        user=sf["user"],
        password=sf["password"],
        account=sf["account"],
    )
    try:
        cur = conn.cursor()
        try:
            cur.execute(f'SHOW SCHEMAS IN DATABASE "{db_id}"')
            rows = cur.fetchall()
            name_idx = next(
                (i for i, d in enumerate(cur.description) if d[0].lower() == "name"),
                1,
            )
            schemas = [r[name_idx] for r in rows]
        finally:
            cur.close()
    finally:
        conn.close()

    return [s for s in schemas if s.upper() not in EXCLUDED_SCHEMAS]


def add_database_to_infini():
    """For each db_id in the spider2-snow JSONL, register all non-system
    schemas as separate InfiniSynapse databases.

    - Database name: ``${db_id}_${schema_name}``. We always namespace by
      ``db_id`` because InfiniSynapse's database ``name`` is a global unique
      key, and Snowflake schemas frequently collide across databases (e.g.
      both ``PATENTS`` and ``PATENTS_USPTO`` have a schema named ``PATENTS``).
      Using just the schema name caused the later db_id to delete-and-replace
      the earlier one, which silently broke
      ``select_databases_by_snowflake_database`` for the loser.
    - Description: `This database is ${db_id} and schema is ${schema_name}`.
    - If the InfiniSynapse database already exists, it is deleted first and
      re-created. Connection is then tested; any failure aborts the run.
    """
    from spider_agent_infini.api.database import (
        add_snowflake_database,
        check_database_exists,
        delete_database,
        test_snowflake_connection,
    )

    db_ids = _load_db_ids(JSONL_PATH)
    logger.info("Found %d distinct db_id(s) in %s", len(db_ids), JSONL_PATH)

    for db_id in db_ids:
        logger.info("=== Processing db_id=%s ===", db_id)
        try:
            schemas = _list_snowflake_schemas(db_id, SNOWFLAKE_CREDENTIAL_PATH)
        except Exception as e:
            _log_failure(f"Failed to list schemas for db_id={db_id!r}: {e}")
            continue

        if not schemas:
            logger.info("[skip] no usable schemas under %s", db_id)
            continue

        logger.info("  schemas: %s", schemas)
        for schema in schemas:
            database_name = f"{db_id}_{schema}"
            description = f"This database is {db_id} and schema is {schema}"

            try:
                if check_database_exists(database_name):
                    logger.info("[delete] %s already exists, deleting", database_name)
                    delete_database(database_name)

                logger.info("[create] %s (schema=%s)", database_name, schema)
                add_snowflake_database(
                    database_name=database_name,
                    snowflake_credential_path=SNOWFLAKE_CREDENTIAL_PATH,
                    snowflake_database=db_id,
                    snowflake_schema=schema,
                    description=description,
                )

                logger.info("[test  ] %s", database_name)
                test_result = test_snowflake_connection(
                    snowflake_credential_path=SNOWFLAKE_CREDENTIAL_PATH,
                    snowflake_database=db_id,
                    snowflake_schema=schema,
                )
                if not (
                    isinstance(test_result, dict) and test_result.get("success")
                ):
                    raise RuntimeError(
                        f"connection test failed: {test_result}"
                    )
                logger.info("[ok    ] %s: %s", database_name, test_result)
            except Exception as e:
                _log_failure(
                    f"Failed to set up database {database_name!r} "
                    f"(db_id={db_id}, schema={schema}): {e}"
                )
                continue


if __name__ == "__main__":
    add_database_to_infini()
