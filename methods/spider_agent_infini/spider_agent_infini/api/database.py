import os

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


if __name__ == "__main__":
    import sys

    name = sys.argv[1] if len(sys.argv) > 1 else "production_db"
    exists = check_database_exists(name)
    print(f"database {name!r} exists: {exists}")
