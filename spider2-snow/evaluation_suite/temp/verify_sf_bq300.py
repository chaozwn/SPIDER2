#!/usr/bin/env python3
"""Final verification: official bq300 SQL on Snowflake vs gold a/b."""
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
SQL_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sf_bq300.sql")
GOLD_A = os.path.join(SUITE_DIR, "gold", "exec_result", "sf_bq300_a.csv")
GOLD_B = os.path.join(SUITE_DIR, "gold", "exec_result", "sf_bq300_b.csv")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sf_bq300_verified.csv")


def connect():
    cred = json.load(open(CRED_PATH))
    kwargs = {k: v for k, v in cred.items() if k != "session_parameters"}
    account = kwargs.get("account", "")
    if account.endswith(".snowflakecomputing.com"):
        kwargs["account"] = account.removesuffix(".snowflakecomputing.com")
    if "host" in kwargs and "account" not in kwargs:
        host = kwargs.pop("host")
        kwargs["account"] = host.removesuffix(".snowflakecomputing.com")
    elif "host" in kwargs:
        kwargs.pop("host", None)
    kwargs["session_parameters"] = cred.get("session_parameters", {})
    return snowflake.connector.connect(database="STACKOVERFLOW", **kwargs)


def main():
    sql = open(SQL_PATH, encoding="utf-8-sig").read()
    conn = connect()
    cur = conn.cursor()
    try:
        cur.execute(sql)
        df = pd.DataFrame(cur.fetchall(), columns=[d[0] for d in cur.description])
        pred = int(df.iloc[0, 0])
        gold_a = int(pd.read_csv(GOLD_A).iloc[0, 0])
        gold_b = int(pd.read_csv(GOLD_B).iloc[0, 0])

        print("SQL result:")
        print(df.to_string(index=False))
        print(f"\nGold A={gold_a}, Gold B={gold_b}")
        print(f"match gold_a? {pred == gold_a}")
        print(f"match gold_b? {pred == gold_b}")
        print(f"accepted (a or b)? {pred in (gold_a, gold_b)}")

        # Also show the winning question
        cur.execute(
            '''
            WITH python2_questions AS (
              SELECT q."id" AS question_id, q."title", q."tags", q."answer_count"
              FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
              WHERE (
                  LOWER(q."tags") LIKE '%python-2%'
                  OR LOWER(q."tags") LIKE '%python-2.x%'
                  OR LOWER(q."title") LIKE '%python 2%'
                  OR LOWER(q."body") LIKE '%python 2%'
                  OR LOWER(q."title") LIKE '%python2%'
                  OR LOWER(q."body") LIKE '%python2%'
                )
                AND LOWER(q."title") NOT LIKE '%python 3%'
                AND LOWER(q."body") NOT LIKE '%python 3%'
                AND LOWER(q."title") NOT LIKE '%python3%'
                AND LOWER(q."body") NOT LIKE '%python3%'
            )
            SELECT q.question_id, q.title, q.tags, q.answer_count, COUNT(*) AS join_count
            FROM python2_questions q
            LEFT JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS a
              ON q.question_id = a."parent_id"
            GROUP BY q.question_id, q.title, q.tags, q.answer_count
            ORDER BY join_count DESC
            LIMIT 3
            '''
        )
        top = pd.DataFrame(cur.fetchall(), columns=[d[0] for d in cur.description])
        print("\nTop-3 matching questions:")
        print(top.to_string(index=False))

        pd.DataFrame({"MAX_ANSWERS": [pred]}).to_csv(OUT, index=False)
        print(f"\nSaved {OUT}")
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
