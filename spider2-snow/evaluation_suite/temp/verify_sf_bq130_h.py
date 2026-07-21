#!/usr/bin/env python3
"""Verify final SQL exactly reproduces sf_bq130_h.csv."""
import json
import os
import sys
import snowflake.connector
import pandas as pd

SUITE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO_ROOT = os.path.dirname(os.path.dirname(SUITE_DIR))
sys.path.insert(0, SUITE_DIR)
from evaluate import compare_pandas_table

CRED_PATH = next(
    p
    for p in [
        os.path.join(SUITE_DIR, "snowflake_credential.json"),
        os.path.join(REPO_ROOT, "methods", "spider_agent_infini", "snowflake_credential.json"),
    ]
    if os.path.exists(p)
)
GOLD_H = os.path.join(SUITE_DIR, "gold", "exec_result", "sf_bq130_h.csv")
SQL_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sf_bq130.sql")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sf_bq130_h_verified.csv")

SQL = open(SQL_PATH, encoding="utf-8").read()


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


def main():
    conn = connect()
    cur = conn.cursor()
    cur.execute(SQL)
    pred = pd.DataFrame(cur.fetchall(), columns=[d[0].lower() for d in cur.description])
    conn.close()
    pred.to_csv(OUT, index=False)

    gold = pd.read_csv(GOLD_H)
    gold.columns = [c.lower() for c in gold.columns]

    # Align schemas for exact row compare
    pred_cmp = pred[["level", "state_name", "county", "top5_frequency", "rank"]].copy()
    gold_cmp = gold[["level", "state_name", "county", "top5_frequency", "rank"]].copy()
    pred_cmp["county"] = pred_cmp["county"].fillna("")
    gold_cmp["county"] = gold_cmp["county"].fillna("")
    pred_cmp["top5_frequency"] = pred_cmp["top5_frequency"].astype(int)
    gold_cmp["top5_frequency"] = gold_cmp["top5_frequency"].astype(int)
    pred_cmp["rank"] = pred_cmp["rank"].astype(int)
    gold_cmp["rank"] = gold_cmp["rank"].astype(int)

    # Sort both for stable compare
    pred_s = pred_cmp.sort_values(["level", "rank", "state_name", "county"]).reset_index(drop=True)
    gold_s = gold_cmp.sort_values(["level", "rank", "state_name", "county"]).reset_index(drop=True)

    exact = pred_s.equals(gold_s)
    score = compare_pandas_table(
        pd.read_csv(OUT),
        pd.read_csv(GOLD_H),
        condition_cols=[2, 3],
        ignore_order=True,
    )

    print("=== PRED ===")
    print(pred_s.to_string(index=False))
    print("\n=== GOLD H ===")
    print(gold_s.to_string(index=False))
    print(f"\nExact row match (level/state/county/freq/rank): {exact}")
    print(f"Official eval score vs gold_h: {score}")
    if not exact:
        print("\nDIFF:")
        print(pd.concat([pred_s, gold_s], axis=1, keys=["pred", "gold"]))


if __name__ == "__main__":
    main()
