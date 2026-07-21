#!/usr/bin/env python3
"""Explore COVID19_NYT schema and try SQL variants for sf_bq130."""
import json
import os
import snowflake.connector
import pandas as pd

SUITE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO_ROOT = os.path.dirname(os.path.dirname(SUITE_DIR))
CRED_PATH = next(
    p
    for p in [
        os.path.join(SUITE_DIR, "snowflake_credential.json"),
        os.path.join(REPO_ROOT, "methods", "spider_agent_infini", "snowflake_credential.json"),
    ]
    if os.path.exists(p)
)


def connect():
    cred = json.load(open(CRED_PATH))
    kwargs = {k: v for k, v in cred.items() if k != "session_parameters"}
    account = kwargs.get("account", "")
    if account.endswith(".snowflakecomputing.com"):
        kwargs["account"] = account.removesuffix(".snowflakecomputing.com")
    elif "host" in kwargs:
        kwargs["account"] = kwargs.pop("host").removesuffix(".snowflakecomputing.com")
    kwargs["session_parameters"] = cred.get("session_parameters", {})
    return snowflake.connector.connect(database="COVID19_NYT", **kwargs)


def run(cur, sql):
    cur.execute(sql)
    cols = [d[0] for d in cur.description]
    return pd.DataFrame(cur.fetchall(), columns=cols)


def main():
    conn = connect()
    cur = conn.cursor()

    print("=== US_STATES schema ===")
    print(run(cur, 'DESCRIBE TABLE COVID19_NYT.COVID19_NYT.US_STATES'))
    print("\n=== US_COUNTIES schema ===")
    print(run(cur, 'DESCRIBE TABLE COVID19_NYT.COVID19_NYT.US_COUNTIES'))

    print("\n=== sample states ===")
    print(run(cur, '''
        SELECT * FROM COVID19_NYT.COVID19_NYT.US_STATES
        WHERE "date" BETWEEN '2020-03-01' AND '2020-03-05'
        ORDER BY "date", "state_name"
        LIMIT 20
    '''))

    print("\n=== date range ===")
    print(run(cur, '''
        SELECT MIN("date") mn, MAX("date") mx, COUNT(*) cnt
        FROM COVID19_NYT.COVID19_NYT.US_STATES
    '''))
    print(run(cur, '''
        SELECT MIN("date") mn, MAX("date") mx, COUNT(*) cnt
        FROM COVID19_NYT.COVID19_NYT.US_COUNTIES
        WHERE "state_name" = 'Illinois'
    '''))

    conn.close()


if __name__ == "__main__":
    main()
