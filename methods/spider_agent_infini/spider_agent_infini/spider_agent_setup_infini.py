import argparse
import json
import logging
import sys
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

# spider2-lite (SQLite) layout — used by `add_sqlite_database_to_infini` and
# the `run_lite.py` runner. Each `local*` instance maps to a `db_id` whose
# corresponding `<db_id>.sqlite` file lives in the spider2-localdb resource
# folder. The mapping itself is mirrored in `local-map.jsonl`.
LITE_JSONL_PATH = str(_REPO_ROOT / "spider2-lite" / "spider2-lite.jsonl")
LITE_DOCUMENT_PATH = str(_REPO_ROOT / "spider2-lite" / "resource" / "documents")
SQLITE_DATABASE_DIR = _REPO_ROOT / "spider2-lite" / "resource" / "databases" / "spider2-localdb"
LOCAL_MAP_PATH = str(SQLITE_DATABASE_DIR / "local-map.jsonl")

EXCLUDED_SCHEMAS = {"INFORMATION_SCHEMA"}


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
        normalize_database_name,
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
            # InfiniSynapse rejects `-` in the data source `name`, and we
            # lowercase to keep lookups deterministic across casing variants.
            # The raw `db_id` / `schema` are still threaded into the SQL
            # config via `snowflake_database` / `snowflake_schema` below, so
            # the actual Snowflake query path is unaffected.
            database_name = normalize_database_name(f"{db_id}_{schema}")
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


def add_remote_database_to_infini():
    """For each db_id in the spider2-snow JSONL, register ONE remote Snowflake
    data source through the nest-admin console API.

    Differences from :func:`add_database_to_infini`:

    - Targets the console API (``console_url``, e.g. ``http://localhost:3000``)
      via the ``sk-*`` API key instead of the InfiniSynapse runtime API.
    - Registers at the *database* level — a single source per ``db_id`` with an
      empty ``snowflake_schema`` — rather than fanning out one source per
      schema. No Snowflake connection / schema listing is performed.
    - The data source name is forced to start with ``remote_`` and carries
      role-based access (``roles`` / ``reviewRoles`` / ``tableAccessRules``),
      all defaulting to :data:`DEFAULT_REMOTE_ROLE_ID`.
    - Connection is NOT tested; the source is added directly. If it already
      exists it is deleted first and re-created.
    """
    from spider_agent_infini.api.database import (
        DEFAULT_REMOTE_ROLE_ID,
        add_remote_snowflake_database,
        check_remote_database_exists,
        delete_remote_database,
        normalize_remote_database_name,
    )

    db_ids = _load_db_ids(JSONL_PATH)
    logger.info("Found %d distinct db_id(s) in %s", len(db_ids), JSONL_PATH)

    for db_id in db_ids:
        database_name = normalize_remote_database_name(db_id)
        description = db_id
        logger.info("=== Processing remote db_id=%s -> %s ===", db_id, database_name)

        try:
            if check_remote_database_exists(database_name):
                logger.info("[delete] %s already exists, deleting", database_name)
                delete_remote_database(database_name)

            logger.info("[create] %s (snowflake_database=%s)", database_name, db_id)
            add_remote_snowflake_database(
                database_name=database_name,
                snowflake_credential_path=SNOWFLAKE_CREDENTIAL_PATH,
                snowflake_database=db_id,
                snowflake_schema="",
                nickname=db_id,
                description=description,
                roles=[DEFAULT_REMOTE_ROLE_ID],
                review_roles=[DEFAULT_REMOTE_ROLE_ID],
            )
            logger.info("[ok    ] %s", database_name)
        except Exception as e:
            _log_failure(
                f"Failed to set up remote database {database_name!r} "
                f"(db_id={db_id}): {e}"
            )
            continue


def _load_sqlite_db_ids(local_map_path: str = LOCAL_MAP_PATH) -> list[str]:
    """Return the unique sqlite ``db_id``s referenced by ``local-map.jsonl``.

    The map file is a small JSONL — typically a single line — whose objects
    are flat ``{instance_id: db_id}`` dicts. We iterate every value in
    insertion order and return the unique ``db_id``s, skipping blanks.
    """
    seen: set[str] = set()
    ordered: list[str] = []
    with open(local_map_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            mapping = json.loads(line)
            if not isinstance(mapping, dict):
                continue
            for db_id in mapping.values():
                if db_id and db_id not in seen:
                    seen.add(db_id)
                    ordered.append(db_id)
    return ordered


def add_sqlite_database_to_infini():
    """For each unique sqlite ``db_id`` in ``local-map.jsonl``, register the
    corresponding ``<db_id>.sqlite`` file as an InfiniSynapse SQLite data
    source.

    - Database name: ``db_id`` itself (e.g. ``E_commerce``, ``Baseball``).
      Each spider2-lite ``db_id`` maps to exactly one ``.sqlite`` file, so
      we don't fan out across schemas the way the Snowflake path does.
    - Upload flow: a fresh ``sqlite_tmp_${db_id}`` directory is created,
      the local ``.sqlite`` file is uploaded into it, and then
      ``/api/ai_database/add`` is called with ``type='sqlite'`` and
      ``config.sqlite_path`` set to the absolute upload path. The server
      validates the SQLite header, atomically moves the file into its
      permanent location and persists the data source.
    - If the InfiniSynapse database already exists, it is deleted first
      (which also drops the previously-finalized SQLite file from the
      server-side ``sqlite/<id>/`` directory) and re-created. Failures are
      logged to ``setup_failures.log`` and the run continues with the next
      ``db_id``.
    """
    from spider_agent_infini.api.database import (
        add_sqlite_database,
        check_database_exists,
        create_upload_directory,
        delete_database,
        normalize_database_name,
        upload_file_to_directory,
    )

    db_ids = _load_sqlite_db_ids()
    logger.info(
        "Found %d distinct sqlite db_id(s) in %s", len(db_ids), LOCAL_MAP_PATH
    )

    for db_id in db_ids:
        sqlite_file = SQLITE_DATABASE_DIR / f"{db_id}.sqlite"
        logger.info("=== Processing sqlite db_id=%s ===", db_id)

        if not sqlite_file.is_file():
            _log_failure(
                f"sqlite file missing for db_id={db_id!r}: {sqlite_file}"
            )
            continue

        # Normalized data source name: lowercase + `-`→`_`. e.g.
        # ``Db-IMDB``→``db_imdb``, ``sqlite-sakila``→``sqlite_sakila``.
        # `select_databases_by_sqlite_db_id` applies the same normalization
        # at lookup time, so callers can still query with the raw db_id.
        database_name = normalize_database_name(db_id)
        description = f"This sqlite database is {db_id}"

        try:
            if check_database_exists(database_name):
                logger.info("[delete] %s already exists, deleting", database_name)
                delete_database(database_name)

            tmp_dir = f"sqlite_tmp_{database_name}"
            logger.info("[mkdir ] %s", tmp_dir)
            create_upload_directory(tmp_dir)

            logger.info("[upload] %s -> %s", sqlite_file, tmp_dir)
            absolute_path = upload_file_to_directory(tmp_dir, str(sqlite_file))

            logger.info("[create] %s (sqlite_path=%s)", database_name, absolute_path)
            add_sqlite_database(
                database_name=database_name,
                sqlite_path=absolute_path,
                description=description,
            )
            logger.info("[ok    ] %s", database_name)
        except Exception as e:
            _log_failure(
                f"Failed to set up sqlite database {database_name!r} "
                f"(db_id={db_id}, file={sqlite_file}): {e}"
            )
            continue


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Register InfiniSynapse data sources for the Spider 2.0 splits. "
            "By default registers BOTH Snowflake (spider2-snow) and SQLite "
            "(spider2-lite) sources; pass a flag to scope to one side."
        ),
    )
    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        "--snowflake-only",
        dest="only",
        action="store_const",
        const="snowflake",
        help="only register Snowflake data sources from spider2-snow.jsonl",
    )
    group.add_argument(
        "--sqlite-only",
        dest="only",
        action="store_const",
        const="sqlite",
        help="only register SQLite data sources from local-map.jsonl",
    )
    group.add_argument(
        "--remote-only",
        dest="only",
        action="store_const",
        const="remote",
        help=(
            "only register remote Snowflake data sources (nest-admin console "
            "API) from spider2-snow.jsonl"
        ),
    )
    parser.add_argument(
        "--types",
        nargs="+",
        choices=("snowflake", "sqlite", "remote"),
        default=None,
        help=(
            "explicit list of source types to register (alternative to "
            "--snowflake-only / --sqlite-only / --remote-only). e.g. "
            "`--types sqlite` or `--types snowflake sqlite`."
        ),
    )
    parser.set_defaults(only=None)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> None:
    args = _parse_args(argv)

    if args.types is not None and args.only is not None:
        # argparse can't express "mutually exclusive across a group and a
        # standalone arg" cleanly, so we enforce it manually.
        print(
            "error: --types is mutually exclusive with --snowflake-only / "
            "--sqlite-only / --remote-only",
            file=sys.stderr,
        )
        raise SystemExit(2)

    if args.types is not None:
        selected = list(dict.fromkeys(args.types))  # preserve order, dedupe
    elif args.only is not None:
        selected = [args.only]
    else:
        selected = ["snowflake", "sqlite"]

    logger.info("Setup will register source type(s): %s", selected)

    # Snowflake first (slower per-db_id because it iterates schemas) so any
    # transient SQLite-side failures don't block the Snowflake pipeline.
    if "snowflake" in selected:
        logger.info("=== STEP: register Snowflake data sources ===")
        add_database_to_infini()
    if "sqlite" in selected:
        logger.info("=== STEP: register SQLite data sources ===")
        add_sqlite_database_to_infini()
    if "remote" in selected:
        logger.info("=== STEP: register remote Snowflake data sources ===")
        add_remote_database_to_infini()


if __name__ == "__main__":
    main()
