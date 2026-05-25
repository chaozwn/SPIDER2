import json
import logging
import mimetypes
import os
import uuid
from pathlib import Path
from typing import Any, Iterable, Sequence

from spider_agent_infini.api.client import DEFAULT_TIMEOUT, InfiniClient, unwrap

logger = logging.getLogger("spider_agent_infini")


def check_database_exists(
    database_name: str,
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> bool:
    """Check whether a database with the given name exists in InfiniSynapse.

    Calls `GET /api/ai_database/getDatabaseByName/{name}` with Bearer auth.
    Returns True iff the API responds 200 and the payload references the name.
    """
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


def delete_database(
    database_name: str,
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> dict[str, Any] | None:
    """Delete a database by name in InfiniSynapse.

    Looks up the database id via `GET /api/ai_database/getDatabaseByName/{name}`
    and then calls `POST /api/ai_database/delete` with `{"ids": [<id>]}`.
    Returns the unwrapped response payload, or None if the database does not exist.
    """
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
    """Select Snowflake data sources whose `config.snowflake_database` matches.

    Iterates all `snowflake` databases, parses each `config` JSON string and
    returns the ones whose `snowflake_database` equals the given value.

    When `enable_matching` is True, the matching databases are enabled via
    `POST /api/ai_database/enabled`. When `disable_others` is True, every other
    Snowflake database is disabled in the same way. Returns the list of
    matching database records.
    """
    items = list_databases(
        type="snowflake",
        credential_path=credential_path,
        timeout=timeout,
    )

    matching: list[dict[str, Any]] = []
    others: list[dict[str, Any]] = []
    for item in items:
        if not isinstance(item, dict):
            continue
        raw_cfg = item.get("config")
        cfg: dict[str, Any] = {}
        if isinstance(raw_cfg, str) and raw_cfg:
            try:
                cfg = json.loads(raw_cfg)
            except (ValueError, TypeError):
                cfg = {}
        elif isinstance(raw_cfg, dict):
            cfg = raw_cfg
        if cfg.get("snowflake_database") == snowflake_database:
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


def wait_for_task(
    task_id: str,
    poll_interval: float = 3.0,
    max_wait: float = 1800.0,
    on_progress: Any = None,
    credential_path: str | os.PathLike | None = None,
    timeout: float = DEFAULT_TIMEOUT,
) -> dict[str, Any]:
    """Poll a task until it is no longer running, or `max_wait` elapses.

    Considers a task finished when `isRunning` is False AND
    ``taskInfo.status`` is one of ``completed``/``failed``/``cancelled``/``error``.

    Args:
        poll_interval: seconds between polls.
        max_wait: hard timeout in seconds; raises ``TimeoutError`` when exceeded.
        on_progress: optional callable ``fn(data) -> None`` invoked on every
            poll for custom logging / streaming the latest message count.

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

        # Mark "alive" once the task runtime is visible on the server, so we
        # don't bail out on the initial race where newTask was just acked but
        # the runtime hasn't registered yet (isRunning=False, status=None).
        if is_running or status or messages or info:
            seen_alive = True

        if seen_alive and not is_running and status in terminal_status:
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
