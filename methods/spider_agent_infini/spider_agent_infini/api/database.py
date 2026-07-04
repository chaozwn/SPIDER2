import json
import logging
import mimetypes
import os
import uuid
from pathlib import Path
from typing import Any, Iterable, Sequence

from spider_agent_infini.api.client import DEFAULT_TIMEOUT, InfiniClient, unwrap

logger = logging.getLogger("spider_agent_infini")

# Default role id granted access (and review) to the remote data sources we
# register through the nest-admin console API. Mirrors the `roles` /
# `reviewRoles` ids used by the front-end "add data source" flow.
DEFAULT_REMOTE_ROLE_ID = "4bd03f9ae690edc1916b7c41"


def normalize_remote_database_name(name: str) -> str:
    """Normalize a name for the nest-admin console (``remote_*``) data source.

    The console server (see ``database.service.ts#normalizeDatabaseName``)
    auto-prefixes ``remote_`` when absent and otherwise keeps the string as-is
    (no lowercasing, no ``-``→``_`` rewriting, unlike
    :func:`normalize_database_name` used for the InfiniSynapse runtime API).
    We pre-compute the same value here so that ``add`` / ``getDatabaseByName``
    / ``delete`` all agree on the stored ``name``.
    """
    name = name.strip()
    return name if name.startswith("remote_") else f"remote_{name}"


def normalize_database_name(name: str) -> str:
    """Normalize a string for use as an InfiniSynapse data source ``name``.

    InfiniSynapse currently rejects ``-`` in registered database names, and we
    also lowercase to keep lookups deterministic across casing variants
    (``Db-IMDB`` and ``db_imdb`` would otherwise be treated as different
    sources). Both the setup pipeline and the runtime selectors call through
    this helper so writes and reads stay in lock-step — never compute the
    server-side name by hand.

    Examples:
        ``"Db-IMDB"        → "db_imdb"``
        ``"E_commerce"     → "e_commerce"``
        ``"sqlite-sakila"  → "sqlite_sakila"``
        ``"GA4_PATENTS"    → "ga4_patents"``
    """
    return name.lower().replace("-", "_")


def check_database_exists(
    database_name: str,
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> bool:
    """Check whether a database with the given name exists in InfiniSynapse.

    Calls `GET /api/ai_database/getDatabaseByName/{name}` with Bearer auth.
    Returns True iff the API responds 200 and the payload references the name.

    The ``database_name`` is auto-normalized via :func:`normalize_database_name`
    before being sent to the server, so callers can pass either the raw
    ``db_id`` (e.g. ``"Db-IMDB"``) or the already-normalized name
    (``"db_imdb"``) and get the same answer.
    """
    database_name = normalize_database_name(database_name)
    client = InfiniClient(credential_path=credential_path, timeout=timeout)
    resp = client.get(
        "/api/ai_database/getDatabaseByName",
        database_name,
        raise_for_status=False,
    )

    if resp.status_code == 404:
        return False
    if resp.status_code != 200:
        resp.raise_for_status()

    try:
        data = unwrap(resp.json())
    except ValueError:
        return False

    if data in (None, "", [], {}):
        return False
    if isinstance(data, dict):
        return bool(data.get("name") or data.get("id"))
    return True


def create_upload_directory(
    directory_name: str,
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> dict[str, Any]:
    """Create a single-level upload directory under the user's upload root.

    Calls ``POST /api/tools/createDirectory`` with ``{directoryName}``.
    Returns the unwrapped payload (typically ``{directoryPath, message}``).

    The server allows only single-level directory names (no path separators)
    matching ``[\\w\\u4E00-\\u9FA5-]+``. Directories prefixed with
    ``sqlite_tmp_`` are recognized by the server as transient SQLite upload
    staging areas and are excluded from normal directory listings; the
    server moves uploaded files out of them when the SQLite data source is
    finalized via ``POST /api/ai_database/add``.
    """
    client = InfiniClient(credential_path=credential_path, timeout=timeout)
    resp = client.post(
        "/api/tools/createDirectory",
        json_body={"directoryName": directory_name},
        raise_for_status=False,
    )
    if resp.status_code == 400 and "already exists" in resp.text.lower():
        return {"directoryPath": directory_name, "message": "already exists"}
    if resp.status_code >= 400:
        resp.raise_for_status()
    return unwrap(resp.json())


def upload_file_to_directory(
    directory: str,
    file_path: str | os.PathLike,
    credential_path: str | os.PathLike | None = None,
    timeout: float = 600.0,
) -> str:
    """Upload a local file under a user-upload directory.

    Calls ``POST /api/tools/upload/{directory}`` with ``multipart/form-data``.
    Returns the absolute server-side path of the saved file (the ``filename``
    field of the response), which can be passed straight into a SQLite data
    source ``config.sqlite_path``.
    """
    fp = Path(file_path)
    if not fp.is_file():
        raise FileNotFoundError(f"upload file not found: {fp}")

    mime, _ = mimetypes.guess_type(fp.name)
    mime = mime or "application/octet-stream"

    client = InfiniClient(credential_path=credential_path, timeout=timeout)
    with open(fp, "rb") as fh:
        files = {"file": (fp.name, fh, mime)}
        resp = client.post("/api/tools/upload", directory, files=files)
    payload = unwrap(resp.json())
    if not isinstance(payload, dict) or not payload.get("filename"):
        raise RuntimeError(
            f"upload to {directory!r} returned unexpected payload: {payload!r}"
        )
    return str(payload["filename"])


def add_sqlite_database(
    database_name: str,
    sqlite_path: str,
    nickname: str | None = None,
    description: str | None = None,
    enabled: int = 1,
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> dict[str, Any]:
    """Register a SQLite data source in InfiniSynapse.

    POSTs to ``/api/ai_database/add`` with ``type='sqlite'``. The ``config``
    field is a JSON-encoded string carrying ``{"sqlite_path": <abs path>}``,
    where ``sqlite_path`` MUST point to a SQLite file under the current
    user's upload root inside a ``sqlite_tmp_*`` staging directory. The
    InfiniSynapse server validates the SQLite header (``SQLite format 3\\0``)
    and atomically moves the file into its permanent location
    (``<upload_root>/sqlite/<databaseId>/database.sqlite``) before persisting
    the data source.
    """
    config = {"sqlite_path": sqlite_path}
    payload: dict[str, Any] = {
        "name": database_name,
        "nickname": nickname or database_name,
        "description": description if description is not None else database_name,
        "type": "sqlite",
        "enabled": enabled,
        "config": json.dumps(config, ensure_ascii=False),
    }

    client = InfiniClient(credential_path=credential_path, timeout=timeout)
    resp = client.post("/api/ai_database/add", json_body=payload)
    return unwrap(resp.json())


def select_databases_by_sqlite_db_id(
    db_id: str,
    enable_matching: bool = True,
    disable_others: bool = True,
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> list[dict[str, Any]]:
    """Select SQLite data sources whose ``name`` matches the given ``db_id``.

    Mirrors :func:`select_databases_by_snowflake_database`, but for SQLite.

    When ``enable_matching`` is True the matching SQLite source is enabled;
    when ``disable_others`` is True every other SQLite source is disabled.
    Snowflake / other-type sources are NOT touched here — orchestrate cross-
    type isolation in the caller if needed.
    """
    items = list_databases(
        type="sqlite",
        credential_path=credential_path,
        timeout=timeout,
    )

    # Normalize on lookup so the caller can pass the raw db_id from the
    # spider2-lite jsonl (e.g. ``Db-IMDB``) and we still match the registered
    # source whose ``name`` was normalized at setup time (``db_imdb``).
    target_name = normalize_database_name(db_id)

    matching: list[dict[str, Any]] = []
    others: list[dict[str, Any]] = []
    for item in items:
        if not isinstance(item, dict):
            continue
        if normalize_database_name(str(item.get("name") or "")) == target_name:
            matching.append(item)
        else:
            others.append(item)

    client = InfiniClient(credential_path=credential_path, timeout=timeout)

    if enable_matching:
        ids = [it["id"] for it in matching if it.get("id")]
        if ids:
            client.post(
                "/api/ai_database/enabled",
                json_body={"ids": ids, "enabled": 1},
            )

    if disable_others:
        ids = [it["id"] for it in others if it.get("id")]
        if ids:
            client.post(
                "/api/ai_database/enabled",
                json_body={"ids": ids, "enabled": 0},
            )

    return matching


def add_snowflake_database(
    database_name: str,
    snowflake_credential_path: str | os.PathLike,
    snowflake_database: str | None = None,
    snowflake_schema: str | None = None,
    nickname: str | None = None,
    description: str | None = None,
    enabled: int = 1,
    deep_optimization: bool = True,
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> dict[str, Any]:
    """Register a Snowflake data source in InfiniSynapse.

    POSTs to `/api/ai_database/update`. The `config` field is sent as a
    JSON-encoded string (matching the InfiniSynapse server contract), built
    from a Snowflake credential JSON containing `account`, `user`, `password`.
    """
    with open(Path(snowflake_credential_path), "r", encoding="utf-8") as f:
        sf = json.load(f)

    config = {
        "snowflake_host": sf["host"],
        "snowflake_username": sf["user"],
        "snowflake_password": sf["password"],
        "snowflake_database": snowflake_database or database_name,
        "snowflake_schema": snowflake_schema or database_name,
        "deep_optimization": deep_optimization,
    }

    payload: dict[str, Any] = {
        "name": database_name,
        "nickname": nickname or database_name,
        "description": description if description is not None else database_name,
        "type": "snowflake",
        "enabled": enabled,
        "config": json.dumps(config, ensure_ascii=False),
    }

    client = InfiniClient(credential_path=credential_path, timeout=timeout)
    resp = client.post("/api/ai_database/add", json_body=payload)
    return unwrap(resp.json())


def test_snowflake_connection(
    snowflake_credential_path: str | os.PathLike,
    snowflake_database: str,
    snowflake_schema: str | None = None,
    deep_optimization: bool = True,
    credential_path: str | os.PathLike | None = None,
    timeout: float = 60.0,
) -> dict[str, Any]:
    """Test a Snowflake connection via `POST /api/ai_database/testConnection`.

    Returns the unwrapped payload, e.g.
    `{"success": True, "message": "连接成功", "latencyMs": 6996}`.
    """
    with open(Path(snowflake_credential_path), "r", encoding="utf-8") as f:
        sf = json.load(f)

    config = {
        "snowflake_host": sf["host"],
        "snowflake_username": sf["user"],
        "snowflake_password": sf["password"],
        "snowflake_database": snowflake_database,
        "snowflake_schema": snowflake_schema or snowflake_database,
        "deep_optimization": deep_optimization,
    }
    payload = {
        "type": "snowflake",
        "config": json.dumps(config, ensure_ascii=False),
    }

    client = InfiniClient(credential_path=credential_path, timeout=timeout)
    resp = client.post("/api/ai_database/testConnection", json_body=payload)
    return unwrap(resp.json())


# ---------------------------------------------------------------------------
# Remote data sources (nest-admin / proxy console API)
#
# These talk to the console API (`console_url`, e.g. http://localhost:3000)
# rather than the InfiniSynapse runtime API. The console layer adds role-based
# access control (`roles` / `reviewRoles` / `tableAccessRules`), stores the
# `config` as a plain JSON object (NOT a JSON-encoded string), and forces every
# data source `name` to start with `remote_`. Auth uses the same `sk-*` API key
# via Bearer token (the front-end uses a JWT; we switch to the API key here).
# ---------------------------------------------------------------------------


def check_remote_database_exists(
    database_name: str,
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> bool:
    """Check whether a remote data source exists via the console API.

    Calls ``GET /api/admin/database/getDatabaseByName/{name}``. The console
    server normalizes the name with a ``remote_`` prefix on lookup, so callers
    may pass either the raw ``db_id`` or the already-prefixed name.
    """
    database_name = normalize_remote_database_name(database_name)
    client = InfiniClient(
        credential_path=credential_path, timeout=timeout, use_console=True
    )
    resp = client.get(
        "/api/admin/database/getDatabaseByName",
        database_name,
        raise_for_status=False,
    )
    if resp.status_code == 404:
        return False
    if resp.status_code != 200:
        resp.raise_for_status()
    try:
        data = unwrap(resp.json())
    except ValueError:
        return False
    if isinstance(data, dict):
        return bool(data.get("id") or data.get("_id") or data.get("name"))
    return bool(data)


def delete_remote_database(
    database_name: str,
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> dict[str, Any] | None:
    """Delete a remote data source by name via the console API.

    Resolves the id through ``GET /api/admin/database/getDatabaseByName/{name}``
    then calls ``POST /api/admin/database/delete`` with ``{"ids": [<id>]}``.
    Returns the unwrapped response, or ``None`` if the source does not exist.
    """
    database_name = normalize_remote_database_name(database_name)
    client = InfiniClient(
        credential_path=credential_path, timeout=timeout, use_console=True
    )
    resp = client.get(
        "/api/admin/database/getDatabaseByName",
        database_name,
        raise_for_status=False,
    )
    if resp.status_code == 404:
        return None
    if resp.status_code != 200:
        resp.raise_for_status()

    data = unwrap(resp.json())
    if not isinstance(data, dict):
        return None
    db_id = data.get("id") or data.get("_id")
    if not db_id:
        return None

    del_resp = client.post(
        "/api/admin/database/delete",
        json_body={"ids": [db_id]},
    )
    try:
        return unwrap(del_resp.json())
    except ValueError:
        return {"status_code": del_resp.status_code}


def add_remote_snowflake_database(
    database_name: str,
    snowflake_credential_path: str | os.PathLike,
    snowflake_database: str | None = None,
    snowflake_schema: str = "",
    nickname: str | None = None,
    description: str | None = None,
    roles: Sequence[str] | None = None,
    review_roles: Sequence[str] | None = None,
    table_access_rules: Sequence[dict[str, Any]] | None = None,
    rag_names: Sequence[str] | None = None,
    public: bool = False,
    deep_optimization: bool = True,
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> dict[str, Any]:
    """Register a remote Snowflake data source via the console API.

    POSTs to ``/api/admin/database/add`` (``DatabaseAddDto``) on the nest-admin
    console. Unlike :func:`add_snowflake_database`, the ``config`` is sent as a
    plain JSON object and the source carries role-based access control.

    The data source is registered at the *database* level: ``snowflake_schema``
    defaults to empty (no per-schema fan-out). The stored ``name`` is forced to
    start with ``remote_`` (the server normalizes it; we pre-normalize so the
    value is deterministic for later lookups).

    Args:
        database_name: logical name (``remote_`` prefix added if missing).
        snowflake_database: Snowflake database/catalog; defaults to the raw
            (un-prefixed) ``database_name``.
        roles / review_roles: role ids granted access / review rights. Both
            default to ``[DEFAULT_REMOTE_ROLE_ID]``.
        table_access_rules: optional per-role table whitelists; defaults to a
            single unrestricted rule for each access role.
    """
    with open(Path(snowflake_credential_path), "r", encoding="utf-8") as f:
        sf = json.load(f)

    name = normalize_remote_database_name(database_name)
    raw_name = name[len("remote_"):] if name.startswith("remote_") else name
    sf_database = snowflake_database or raw_name

    role_ids = list(roles) if roles is not None else [DEFAULT_REMOTE_ROLE_ID]
    review_role_ids = (
        list(review_roles) if review_roles is not None else list(role_ids)
    )
    if table_access_rules is not None:
        rules = list(table_access_rules)
    else:
        rules = [{"role": rid, "tables": []} for rid in role_ids]

    config = {
        "snowflake_host": sf["host"],
        "snowflake_username": sf["user"],
        "snowflake_password": sf["password"],
        "snowflake_database": sf_database,
        "snowflake_schema": snowflake_schema,
        "deep_optimization": deep_optimization,
    }

    payload: dict[str, Any] = {
        "name": name,
        "nickname": nickname or raw_name,
        "description": description if description is not None else raw_name,
        "type": "snowflake",
        "ragNames": list(rag_names) if rag_names is not None else [],
        "roles": role_ids,
        "reviewRoles": review_role_ids,
        "tableAccessRules": rules,
        "public": public,
        "config": config,
    }

    client = InfiniClient(
        credential_path=credential_path, timeout=timeout, use_console=True
    )
    resp = client.post("/api/admin/database/add", json_body=payload)
    return unwrap(resp.json())


def delete_database(
    database_name: str,
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> dict[str, Any] | None:
    """Delete a database by name in InfiniSynapse.

    Looks up the database id via `GET /api/ai_database/getDatabaseByName/{name}`
    and then calls `POST /api/ai_database/delete` with `{"ids": [<id>]}`.
    Returns the unwrapped response payload, or None if the database does not exist.

    The ``database_name`` is auto-normalized via :func:`normalize_database_name`
    before being sent, so callers can pass either the raw ``db_id`` or the
    normalized name interchangeably.
    """
    database_name = normalize_database_name(database_name)
    client = InfiniClient(credential_path=credential_path, timeout=timeout)
    resp = client.get(
        "/api/ai_database/getDatabaseByName",
        database_name,
        raise_for_status=False,
    )
    if resp.status_code == 404:
        return None
    if resp.status_code != 200:
        resp.raise_for_status()

    data = unwrap(resp.json())
    if not isinstance(data, dict) or not data.get("id"):
        return None

    del_resp = client.post(
        "/api/ai_database/delete",
        json_body={"ids": [data["id"]]},
    )
    try:
        return unwrap(del_resp.json())
    except ValueError:
        return {"status_code": del_resp.status_code}


def delete_databases(
    ids: list[str],
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> dict[str, Any]:
    """Batch delete databases by id via `POST /api/ai_database/delete`."""
    client = InfiniClient(credential_path=credential_path, timeout=timeout)
    resp = client.post("/api/ai_database/delete", json_body={"ids": list(ids)})
    try:
        return unwrap(resp.json())
    except ValueError:
        return {"status_code": resp.status_code}


def list_available_engines(
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> list[dict[str, Any]]:
    """List selectable InfiniSQL engines via ``GET /api/ai_byzer/available``.

    Returns enabled engines the current user may bind to a task via
    ``engineId`` on ``newTask``. Each item typically includes ``id``,
    ``name``, and ``url``.
    """
    client = InfiniClient(credential_path=credential_path, timeout=timeout)
    resp = client.get("/api/ai_byzer/available")
    data = unwrap(resp.json())
    if isinstance(data, dict) and "items" in data:
        return list(data["items"] or [])
    if isinstance(data, list):
        return data
    return []


def list_databases(
    name: str | None = None,
    type: str | None = None,
    enabled: int | None = None,
    source: str = "all",
    page: int = 1,
    page_size: int = 10000,
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> list[dict[str, Any]]:
    """List databases via `GET /api/ai_database/list`.

    Returns the `items` array from the paginated response. Defaults to a large
    `pageSize` so that a single call typically returns everything.
    """
    params: dict[str, Any] = {"page": page, "pageSize": page_size, "source": source}
    if name is not None:
        params["name"] = name
    if type is not None:
        params["type"] = type
    if enabled is not None:
        params["enabled"] = enabled

    client = InfiniClient(credential_path=credential_path, timeout=timeout)
    resp = client.get("/api/ai_database/list", params=params)
    data = unwrap(resp.json())
    if isinstance(data, dict) and "items" in data:
        return list(data["items"] or [])
    if isinstance(data, list):
        return data
    return []


def clear_all_databases(
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> dict[str, Any] | None:
    """Delete every database registered in InfiniSynapse.

    Lists all databases via `/api/ai_database/list` and batch-deletes them via
    `POST /api/ai_database/delete`. Returns the unwrapped delete response, or
    `None` if there was nothing to delete.
    """
    items = list_databases(credential_path=credential_path, timeout=timeout)
    ids = [item["id"] for item in items if isinstance(item, dict) and item.get("id")]
    if not ids:
        return None
    return delete_databases(ids, credential_path=credential_path, timeout=timeout)


def select_databases_by_snowflake_database(
    snowflake_database: str,
    enable_matching: bool = True,
    disable_others: bool = True,
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> list[dict[str, Any]]:
    """Select the remote Snowflake data source whose ``name`` matches ``db_id``.

    Each spider2-snow ``db_id`` maps to exactly one nest-admin remote Snowflake
    source registered as ``remote_<db_id>`` (see
    :func:`normalize_remote_database_name` and
    :func:`add_remote_database_to_infini`).

    When ``enable_matching`` is True the matching source is enabled; when
    ``disable_others`` is True every other Snowflake source is disabled.
    Prefer passing the resolved id(s) via ``databaseIds`` on ``newTask``
    (see :func:`new_task`) instead of toggling the global enabled-set when
    running concurrent workers.
    """
    items = list_databases(
        type="snowflake",
        credential_path=credential_path,
        timeout=timeout,
    )

    target_name = normalize_remote_database_name(snowflake_database)

    matching: list[dict[str, Any]] = []
    others: list[dict[str, Any]] = []
    for item in items:
        if not isinstance(item, dict):
            continue
        if normalize_remote_database_name(str(item.get("name") or "")) == target_name:
            matching.append(item)
        else:
            others.append(item)

    client = InfiniClient(credential_path=credential_path, timeout=timeout)

    if enable_matching:
        ids = [it["id"] for it in matching if it.get("id")]
        if ids:
            client.post(
                "/api/ai_database/enabled",
                json_body={"ids": ids, "enabled": 1},
            )

    if disable_others:
        ids = [it["id"] for it in others if it.get("id")]
        if ids:
            client.post(
                "/api/ai_database/enabled",
                json_body={"ids": ids, "enabled": 0},
            )

    return matching


def upload_task_file(
    task_id: str,
    file_path: str | os.PathLike,
    subdir: str | None = None,
    naming: str | None = None,
    credential_path: str | os.PathLike | None = None,
    timeout: float = 120.0,
) -> dict[str, Any]:
    """Pre-upload a single file to a task workspace.

    Calls `POST /api/tools/taskUpload/{taskId}` with `multipart/form-data`.
    Returns the unwrapped response, e.g.
    `{"filename", "logicalPath", "assetId", "name", "size", "type"}`.

    Args:
        subdir: optional sub-directory under the task workspace (e.g. ``data``,
            ``upload_documents``, ``images``).
        naming: ``original`` (default on server) or ``hash`` for md5-named
            de-duplicated uploads (recommended for pasted images).
    """
    fp = Path(file_path)
    if not fp.is_file():
        raise FileNotFoundError(f"upload file not found: {fp}")

    params: dict[str, Any] = {}
    if subdir:
        params["subdir"] = subdir
    if naming:
        params["naming"] = naming

    mime, _ = mimetypes.guess_type(fp.name)
    mime = mime or "application/octet-stream"

    client = InfiniClient(credential_path=credential_path, timeout=timeout)
    with open(fp, "rb") as fh:
        files = {"file": (fp.name, fh, mime)}
        resp = client.post(
            "/api/tools/taskUpload",
            task_id,
            params=params or None,
            files=files,
        )
    return unwrap(resp.json())


def _build_file_items(
    task_id: str,
    file_paths: Sequence[str | os.PathLike] | None,
    reference_paths: Sequence[str | os.PathLike] | None,
    credential_path: str | os.PathLike | None,
    timeout: float,
) -> list[dict[str, Any]]:
    """Upload local files and produce `WebviewMessageFileItemDto` entries."""
    items: list[dict[str, Any]] = []

    def _upload(paths: Iterable[str | os.PathLike], file_type: str, subdir: str | None) -> None:
        for p in paths:
            fp = Path(p)
            up = upload_task_file(
                task_id=task_id,
                file_path=fp,
                subdir=subdir,
                credential_path=credential_path,
                timeout=timeout,
            )
            mime, _ = mimetypes.guess_type(fp.name)
            items.append(
                {
                    "name": up.get("name") or fp.name,
                    "size": int(up.get("size") or fp.stat().st_size),
                    "type": up.get("type") or mime or "application/octet-stream",
                    "logicalPath": up.get("logicalPath"),
                    "assetId": up.get("assetId"),
                    "fileType": file_type,
                }
            )

    if file_paths:
        _upload(file_paths, file_type="data", subdir=None)
    if reference_paths:
        _upload(reference_paths, file_type="reference", subdir="upload_documents")
    return items


def new_task(
    text: str,
    task_id: str | None = None,
    file_paths: Sequence[str | os.PathLike] | None = None,
    reference_paths: Sequence[str | os.PathLike] | None = None,
    files: Sequence[dict[str, Any]] | None = None,
    images: Sequence[str] | None = None,
    database_ids: Sequence[str] | None = None,
    rag_ids: Sequence[str] | None = None,
    engine_id: str | None = None,
    command_id: str | None = None,
    client_message_id: str | None = None,
    extra: dict[str, Any] | None = None,
    credential_path: str | os.PathLike | None = None,
    timeout: float = 300.0,
) -> dict[str, Any]:
    """Create a new InfiniSynapse task via `POST /api/ai/message`.

    Equivalent to the front-end ``{type: 'newTask', ...}`` flow:

    1. (Optional) Generate a ``taskId`` for idempotency / scoping uploads.
    2. Pre-upload any local files via `POST /api/tools/taskUpload/{taskId}`,
       splitting between ``data`` (default) and ``reference``
       (``upload_documents/`` sub-directory, read by Agent via ``read_file``).
    3. Send the ``newTask`` message with the pre-uploaded ``files`` items.

    Args:
        text: first user message / task description.
        task_id: existing taskId for idempotency; auto-generated if omitted.
        file_paths: local data files to pre-upload (``fileType=data``).
        reference_paths: local reference docs (``fileType=reference``),
            placed under ``upload_documents/``.
        files: already pre-uploaded ``WebviewMessageFileItemDto`` items
            (merged after `file_paths` / `reference_paths`).
        images: image list (Base64 data URLs or accessible URLs).
        database_ids: per-task data source ids to scope this task to (sent as
            ``databaseIds``). When provided, the task uses exactly these
            sources regardless of which sources are globally enabled — this
            is what lets concurrent tasks target different databases without
            a global enable/disable toggle.
        rag_ids: per-task RAG knowledge-base ids (sent as ``ragIds``).
        engine_id: per-task InfiniSQL engine id (sent as ``engineId``). When
            provided, all Infinity SQL for this task runs on that engine.
        command_id / client_message_id: idempotency identifiers; auto-filled
            if omitted.
        extra: additional fields to merge into the request body (e.g.
            ``connId``, ``chatSettings``, ``autoApprovalSettings``).

    Returns:
        The unwrapped server response (typically the ack /
        `AiMessageStateResponseDto`).
    """
    tid = task_id or str(uuid.uuid4())
    cmd_id = command_id or str(uuid.uuid4())
    cli_msg_id = client_message_id or str(uuid.uuid4())

    file_items: list[dict[str, Any]] = []
    if file_paths or reference_paths:
        file_items.extend(
            _build_file_items(
                task_id=tid,
                file_paths=file_paths,
                reference_paths=reference_paths,
                credential_path=credential_path,
                timeout=timeout,
            )
        )
    if files:
        file_items.extend(files)

    payload: dict[str, Any] = {
        "type": "newTask",
        "taskId": tid,
        "text": text,
        "commandId": cmd_id,
        "clientMessageId": cli_msg_id,
    }
    if images:
        payload["images"] = list(images)
    if file_items:
        payload["files"] = file_items
    if database_ids:
        payload["databaseIds"] = list(database_ids)
    if rag_ids:
        payload["ragIds"] = list(rag_ids)
    if engine_id:
        payload["engineId"] = engine_id
    if extra:
        payload.update(extra)

    client = InfiniClient(credential_path=credential_path, timeout=timeout)
    resp = client.post("/api/ai/message", json_body=payload)
    return unwrap(resp.json())


def list_task_workspace(
    task_id: str,
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> dict[str, Any]:
    """List a task's workspace files via `GET /api/ai_task/getTaskWorkspace/{taskId}`.

    Returns `{"cwd": "...", "files": ["a.csv", "sub/b.json", ...]}`.
    """
    client = InfiniClient(credential_path=credential_path, timeout=timeout)
    resp = client.get("/api/ai_task/getTaskWorkspace", task_id)
    return unwrap(resp.json())


def download_task_file(
    task_id: str,
    remote_path: str,
    dest: str | os.PathLike,
    credential_path: str | os.PathLike | None = None,
    timeout: float = 300.0,
    chunk_size: int = 64 * 1024,
) -> str:
    """Download a single file from the task workspace.

    Calls `GET /api/tools/storage/downloadTaskFile/{taskId}?path=<remote_path>`,
    streaming the response to disk. If ``dest`` is an existing directory,
    the file is saved as ``dest/<basename(remote_path)>``; otherwise ``dest``
    is treated as the full destination path.

    Returns the local absolute path to the saved file.
    """
    from urllib.parse import quote as _quote

    client = InfiniClient(credential_path=credential_path, timeout=timeout)
    url = (
        f"{client.api_url}/api/tools/storage/downloadTaskFile/"
        f"{_quote(task_id, safe='')}?path={_quote(remote_path, safe='')}"
    )

    dest_path = Path(dest)
    if dest_path.exists() and dest_path.is_dir():
        dest_path = dest_path / Path(remote_path).name
    dest_path.parent.mkdir(parents=True, exist_ok=True)

    import requests as _requests
    with _requests.get(
        url,
        headers=client._headers(),
        stream=True,
        timeout=timeout,
    ) as resp:
        resp.raise_for_status()
        with open(dest_path, "wb") as fh:
            for chunk in resp.iter_content(chunk_size=chunk_size):
                if chunk:
                    fh.write(chunk)
    return str(dest_path.resolve())


def download_task_zip(
    task_id: str,
    dest: str | os.PathLike,
    credential_path: str | os.PathLike | None = None,
    timeout: float = 600.0,
    chunk_size: int = 256 * 1024,
) -> str:
    """Download the whole task workspace as a ZIP.

    Calls `GET /api/ai_task/downloadZip?taskId=<id>`. Server-side ignores
    ``node_modules`` and other dot-prefixed cache directories. Returns the
    local absolute path of the saved zip.
    """
    client = InfiniClient(credential_path=credential_path, timeout=timeout)
    url = f"{client.api_url}/api/ai_task/downloadZip"

    dest_path = Path(dest)
    if dest_path.exists() and dest_path.is_dir():
        dest_path = dest_path / f"{task_id}.zip"
    dest_path.parent.mkdir(parents=True, exist_ok=True)

    import requests as _requests
    with _requests.get(
        url,
        params={"taskId": task_id},
        headers=client._headers(),
        stream=True,
        timeout=timeout,
    ) as resp:
        resp.raise_for_status()
        with open(dest_path, "wb") as fh:
            for chunk in resp.iter_content(chunk_size=chunk_size):
                if chunk:
                    fh.write(chunk)
    return str(dest_path.resolve())


def download_task_workspace(
    task_id: str,
    dest_dir: str | os.PathLike,
    credential_path: str | os.PathLike | None = None,
    timeout: float = 300.0,
) -> list[str]:
    """Convenience helper: list workspace + download each file individually.

    Files are saved preserving their relative paths under ``dest_dir``.
    Returns the list of local absolute paths.
    """
    ws = list_task_workspace(
        task_id, credential_path=credential_path, timeout=timeout
    )
    files = ws.get("files") or []
    out_root = Path(dest_dir)
    out_root.mkdir(parents=True, exist_ok=True)
    saved: list[str] = []
    for rel in files:
        local = out_root / rel
        local.parent.mkdir(parents=True, exist_ok=True)
        saved.append(
            download_task_file(
                task_id,
                rel,
                local,
                credential_path=credential_path,
                timeout=timeout,
            )
        )
    return saved


def _iter_sse(resp) -> Iterable[tuple[str, str]]:
    """Minimal SSE parser: yields ``(event, data)`` tuples."""
    event = ""
    data_lines: list[str] = []
    for raw in resp.iter_lines(decode_unicode=True):
        if raw is None:
            continue
        if raw == "":
            if data_lines:
                yield event or "message", "\n".join(data_lines)
            event = ""
            data_lines = []
            continue
        if raw.startswith(":"):
            continue
        if raw.startswith("event:"):
            event = raw[6:].strip()
        elif raw.startswith("data:"):
            data_lines.append(raw[5:].lstrip())


def new_task_and_wait(
    text: str,
    task_id: str | None = None,
    file_paths: Sequence[str | os.PathLike] | None = None,
    reference_paths: Sequence[str | os.PathLike] | None = None,
    files: Sequence[dict[str, Any]] | None = None,
    images: Sequence[str] | None = None,
    on_message: Any = None,
    stop_on_ask: bool = True,
    sse_connect_timeout: float = 15.0,
    sse_read_timeout: float | None = 60.0,
    credential_path: str | os.PathLike | None = None,
    timeout: float = 300.0,
    extra: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Create a `newTask` and stream SSE events until the task completes.

    Equivalent to the ``infinisynapse-cli task new`` flow:
    1. Subscribe to ``GET /api/ai/events?connId=<connId>`` (SSE).
    2. POST ``/api/ai/message`` with ``type='newTask'`` and the same ``connId``.
    3. Read SSE events; stop when a ``message.add`` with
       ``say='completion_result' && !partial`` arrives.

    Args:
        on_message: optional callback ``fn(event_name, message_dict)``.
        stop_on_ask: if True, also stop when the Agent emits a non-partial
            ``ask`` (other than ``completion_result``) so the script doesn't
            hang waiting for user input. Set False if you intend to call
            ``askResponse`` from another thread.

    Returns: ``{taskId, connId, lastMessage, ack}``.
    """
    import threading
    import requests as _requests

    conn_id = str(uuid.uuid4())
    tid = task_id or str(uuid.uuid4())

    client = InfiniClient(credential_path=credential_path, timeout=timeout)
    sse_url = f"{client.api_url}/api/ai/events"
    sse_headers = client._headers({"Accept": "text/event-stream"})

    sse_resp = _requests.get(
        sse_url,
        params={"connId": conn_id},
        headers=sse_headers,
        stream=True,
        timeout=(sse_connect_timeout, sse_read_timeout),
    )
    sse_resp.raise_for_status()

    file_items: list[dict[str, Any]] = []
    if file_paths or reference_paths:
        file_items.extend(
            _build_file_items(
                task_id=tid,
                file_paths=file_paths,
                reference_paths=reference_paths,
                credential_path=credential_path,
                timeout=timeout,
            )
        )
    if files:
        file_items.extend(files)

    payload: dict[str, Any] = {
        "type": "newTask",
        "taskId": tid,
        "connId": conn_id,
        "text": text,
        "commandId": str(uuid.uuid4()),
        "clientMessageId": str(uuid.uuid4()),
    }
    if images:
        payload["images"] = list(images)
    if file_items:
        payload["files"] = file_items
    if extra:
        payload.update(extra)

    post_result: dict[str, Any] = {}

    def _post() -> None:
        try:
            resp = client.post("/api/ai/message", json_body=payload)
            post_result["ack"] = unwrap(resp.json())
        except Exception as exc:  # noqa: BLE001
            post_result["error"] = exc

    poster = threading.Thread(target=_post, daemon=True)
    poster.start()

    last_message: dict[str, Any] | None = None
    try:
        for event, data in _iter_sse(sse_resp):
            if event == "heartbeat":
                continue
            if event not in ("message.partial", "message.add"):
                continue
            try:
                obj = json.loads(data)
            except (ValueError, TypeError):
                continue
            msg = obj.get("message") or {}
            if callable(on_message):
                try:
                    on_message(event, msg)
                except Exception:
                    logger.exception("on_message callback failed")

            mtype = msg.get("type")
            partial = bool(msg.get("partial"))
            if mtype == "say" and not partial:
                last_message = msg
                if event == "message.add" and msg.get("say") == "completion_result":
                    break
            elif mtype == "ask" and not partial:
                if msg.get("ask") != "completion_result":
                    last_message = msg
                if stop_on_ask:
                    break
    except (_requests.exceptions.ReadTimeout, _requests.exceptions.ConnectionError) as exc:
        logger.info(
            "SSE stream for task %s ended or timed out; falling back to polling: %s",
            tid,
            exc,
        )
    finally:
        try:
            sse_resp.close()
        except Exception:
            pass

    poster.join(timeout=10)
    if "error" in post_result and "ack" not in post_result:
        raise post_result["error"]

    return {
        "taskId": tid,
        "connId": conn_id,
        "lastMessage": last_message,
        "ack": post_result.get("ack"),
    }


def ask_task(
    task_id: str,
    text: str,
    ask_response: str = "messageResponse",
    file_paths: Sequence[str | os.PathLike] | None = None,
    reference_paths: Sequence[str | os.PathLike] | None = None,
    files: Sequence[dict[str, Any]] | None = None,
    images: Sequence[str] | None = None,
    command_id: str | None = None,
    client_message_id: str | None = None,
    extra: dict[str, Any] | None = None,
    credential_path: str | os.PathLike | None = None,
    timeout: float = 300.0,
) -> dict[str, Any]:
    """Continue an InfiniSynapse task via ``POST /api/ai/message`` (``askResponse``).

    Equivalent to the front-end / CLI ``task ask`` flow: reply to the Agent's
    pending Ask (or resume a completed task) with user text.

    Args:
        task_id: existing task id from :func:`new_task`.
        text: user follow-up message.
        ask_response: one of ``messageResponse``, ``yesButtonClicked``,
            ``noButtonClicked`` (defaults to ``messageResponse``).
        file_paths / reference_paths / files / images: optional attachments,
            uploaded the same way as :func:`new_task`.
    """
    cmd_id = command_id or str(uuid.uuid4())
    cli_msg_id = client_message_id or str(uuid.uuid4())

    file_items: list[dict[str, Any]] = []
    if file_paths or reference_paths:
        file_items.extend(
            _build_file_items(
                task_id=task_id,
                file_paths=file_paths,
                reference_paths=reference_paths,
                credential_path=credential_path,
                timeout=timeout,
            )
        )
    if files:
        file_items.extend(files)

    payload: dict[str, Any] = {
        "type": "askResponse",
        "taskId": task_id,
        "askResponse": ask_response,
        "text": text,
        "commandId": cmd_id,
        "clientMessageId": cli_msg_id,
    }
    if images:
        payload["images"] = list(images)
    if file_items:
        payload["files"] = file_items
    if extra:
        payload.update(extra)

    client = InfiniClient(credential_path=credential_path, timeout=timeout)
    resp = client.post("/api/ai/message", json_body=payload)
    return unwrap(resp.json())


def get_task_data(
    task_id: str,
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> dict[str, Any]:
    """Fetch a task's full data via `GET /api/ai_task/tasks?taskId=...`.

    Returns the unwrapped payload, typically
    ``{"taskInfo": {..., "status": "running"|"completed"|...},
        "messages": [...], "isRunning": bool}``.
    """
    client = InfiniClient(credential_path=credential_path, timeout=timeout)
    resp = client.get("/api/ai_task/tasks", params={"taskId": task_id})
    return unwrap(resp.json())


def _last_non_partial_message(messages: list[dict[str, Any]]) -> dict[str, Any] | None:
    """Return the last finalized (non-partial) message, if any."""
    for m in reversed(messages or []):
        if not isinstance(m, dict):
            continue
        if m.get("partial"):
            continue
        return m
    return None


def _is_terminal_message(
    msg: dict[str, Any] | None,
    *,
    terminal_on_any_ask: bool = True,
) -> bool:
    """Detect a terminal "task is done" message from the slimmed message stream.

    The server-side `keepRegisteredOnAskExit=true` path leaves the Infini
    instance registered after `attempt_completion`, so `isRunning` stays True
    and `taskInfo.status` stays "running" until the runtime is parked
    (default 10min) or the user resumes the task. The authoritative signal in
    that window is the message stream itself, mirroring how the web UI and
    `new_task_and_wait` detect completion.
    """
    if not msg:
        return False
    mtype = msg.get("type")
    if mtype == "say" and msg.get("say") == "completion_result":
        return True
    if mtype == "ask":
        ask = msg.get("ask")
        if ask == "completion_result":
            return True
        if not terminal_on_any_ask:
            return False
        # Any finalized ask other than the user-driven resume prompts means the
        # agent has handed control back: completion_result, followup,
        # api_req_failed, mistake_limit_reached, plan_mode_response, etc.
        if ask and ask not in ("resume_task", "resume_completed_task"):
            return True
    return False


def wait_for_task(
    task_id: str,
    poll_interval: float = 3.0,
    max_wait: float = 1800.0,
    on_progress: Any = None,
    terminal_on_any_ask: bool = True,
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> dict[str, Any]:
    """Poll a task until it has handed control back to the caller.

    A task is considered finished when **any** of the following holds:

    1. ``taskInfo.status`` is a terminal status
       (``completed``/``failed``/``cancelled``/``error``); or
    2. The last finalized (``partial=false``) message is a ``completion_result``
       or any non-resume ``ask`` — i.e. the agent has produced its final
       deliverable and is waiting for user input. This is required because the
       server keeps the Infini instance registered after ``attempt_completion``
       (``keepRegisteredOnAskExit=true``), so ``isRunning`` will remain True
       and ``taskInfo.status`` will remain ``"running"`` even though the task
       is, from the agent's perspective, done.

    Args:
        poll_interval: seconds between polls.
        max_wait: hard timeout in seconds; raises ``TimeoutError`` when exceeded.
        on_progress: optional callable ``fn(data) -> None`` invoked on every
            poll for custom logging / streaming the latest message count.
        terminal_on_any_ask: when True, any finalized non-resume ``ask`` is
            treated as terminal. Benchmark runners pass False so transient
            tool-error / retry prompts do not cause an early workspace download.

    Returns:
        The final ``get_task_data`` payload.
    """
    import time

    terminal_status = {"completed", "failed", "cancelled", "canceled", "error"}
    start = time.time()
    seen_alive = False
    while True:
        data = get_task_data(
            task_id, credential_path=credential_path, timeout=timeout
        )
        if callable(on_progress):
            try:
                on_progress(data)
            except Exception:
                logger.exception("on_progress callback failed")

        is_running = bool(data.get("isRunning"))
        info = data.get("taskInfo") or {}
        status = ""
        if isinstance(info, dict):
            status = str(info.get("status") or "").lower()
        messages = data.get("messages") or []

        if is_running or status or messages or info:
            seen_alive = True

        if seen_alive and status in terminal_status:
            return data

        if seen_alive and _is_terminal_message(
            _last_non_partial_message(messages),
            terminal_on_any_ask=terminal_on_any_ask,
        ):
            return data

        if time.time() - start > max_wait:
            raise TimeoutError(
                f"wait_for_task({task_id}) exceeded {max_wait}s; "
                f"last status={status!r}, isRunning={is_running}"
            )
        time.sleep(poll_interval)


if __name__ == "__main__":
    import sys

    name = sys.argv[1] if len(sys.argv) > 1 else "production_db"
    exists = check_database_exists(name)
    logger.info("database %r exists: %s", name, exists)
