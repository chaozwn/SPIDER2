import json
import os
from pathlib import Path
from typing import Any

from spider_agent_infini.api.client import DEFAULT_TIMEOUT, InfiniClient, unwrap


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
        "snowflake_host": sf["account"],
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
        "snowflake_host": sf["account"],
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


if __name__ == "__main__":
    import sys

    name = sys.argv[1] if len(sys.argv) > 1 else "production_db"
    exists = check_database_exists(name)
    print(f"database {name!r} exists: {exists}")
