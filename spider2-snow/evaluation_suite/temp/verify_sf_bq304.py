#!/usr/bin/env python3
"""Verify sf_bq304 gold SQL against gold CSV variants a/b/c."""
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
SQL_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sf_bq304.sql")
GOLD_DIR = os.path.join(SUITE_DIR, "gold", "exec_result")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sf_bq304_verified.csv")


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
    print("Connecting...")
    conn = connect()
    cur = conn.cursor()
    print("Executing SQL (may take a while)...")
    cur.execute(sql)
    cols = [d[0] for d in cur.description]
    rows = cur.fetchall()
    df = pd.DataFrame(rows, columns=cols)
    df.columns = [c.lower() for c in df.columns]
    print("Result shape:", df.shape)
    print("Columns:", list(df.columns))
    print("Tags:", df["tag"].value_counts().to_dict())
    df.to_csv(OUT, index=False)
    print("Wrote", OUT)

    gold_a = pd.read_csv(os.path.join(GOLD_DIR, "sf_bq304_a.csv"))
    gold_b = pd.read_csv(os.path.join(GOLD_DIR, "sf_bq304_b.csv"))
    gold_c = pd.read_csv(os.path.join(GOLD_DIR, "sf_bq304_c.csv"))

    pred_a = set(zip(df["tag"], df["title"], df["view_count"].astype(int)))
    ga = set(zip(gold_a["tag"], gold_a["title"], gold_a["view_count"].astype(int)))
    print("\n=== vs gold_a (tag,title,view_count) ===")
    print("pred", len(pred_a), "gold", len(ga), "intersect", len(pred_a & ga))
    print("only_pred", len(pred_a - ga), "only_gold", len(ga - pred_a))

    pred_c = set(
        zip(df["question_id"].astype(int), df["view_count"].astype(int), df["tag"])
    )
    gc = set(
        zip(gold_c["id"].astype(int), gold_c["view_count"].astype(int), gold_c["TAG_NAME"])
    )
    print("\n=== vs gold_c (id,view_count,TAG_NAME) ===")
    print("pred", len(pred_c), "gold", len(gc), "intersect", len(pred_c & gc))
    print("only_pred", len(pred_c - gc), "only_gold", len(gc - pred_c))

    pred_b = set(zip(df["tag"], df["question_id"].astype(int), df["tags"]))
    gb = set(zip(gold_b["tag"], gold_b["question_id"].astype(int), gold_b["tags"]))
    print("\n=== vs gold_b (tag,question_id,tags) ===")
    print("pred", len(pred_b), "gold", len(gb), "intersect", len(pred_b & gb))
    print("only_pred", len(pred_b - gb), "only_gold", len(gb - pred_b))

    if pred_a != ga:
        print("\nSample only_gold_a:")
        for x in list(ga - pred_a)[:5]:
            print(" ", x)
        print("Sample only_pred_a:")
        for x in list(pred_a - ga)[:5]:
            print(" ", x)

    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
