#!/usr/bin/env python3
import json
import math
import os
import sys
import pandas as pd

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SUITE_DIR = os.path.dirname(SCRIPT_DIR)
REPO_ROOT = os.path.dirname(os.path.dirname(SUITE_DIR))

sys.path.insert(0, SUITE_DIR)

import snowflake.connector

SQL_PATH = os.path.join(SCRIPT_DIR, "sf_bq069.sql")
OUT_PATH = os.path.join(SCRIPT_DIR, "sf_bq069_result.csv")
GOLD_DIR = os.path.join(SUITE_DIR, "gold", "exec_result")
CRED_PATH = os.path.join(SUITE_DIR, "snowflake_credential.json")


def normalize(value):
    if pd.isna(value):
        return 0
    return value


def vectors_match(v1, v2, tol=1e-2, ignore_order_=False):
    v1 = [normalize(x) for x in v1]
    v2 = [normalize(x) for x in v2]
    if ignore_order_:
        v1 = sorted(v1, key=lambda x: (x is None, str(x), isinstance(x, (int, float))))
        v2 = sorted(v2, key=lambda x: (x is None, str(x), isinstance(x, (int, float))))
    if len(v1) != len(v2):
        return False
    for a, b in zip(v1, v2):
        if pd.isna(a) and pd.isna(b):
            continue
        if isinstance(a, (int, float)) and isinstance(b, (int, float)):
            if not math.isclose(float(a), float(b), abs_tol=tol):
                return False
        elif a != b:
            return False
    return True


def compare_pandas_table(pred, gold, condition_cols=None, ignore_order=False):
    condition_cols = condition_cols or []
    if condition_cols:
        gold_cols = gold.iloc[:, condition_cols]
    else:
        gold_cols = gold
    pred_cols = pred
    t_gold_list = gold_cols.transpose().values.tolist()
    t_pred_list = pred_cols.transpose().values.tolist()
    for gold_vec in t_gold_list:
        if not any(vectors_match(gold_vec, pred_vec, ignore_order_=ignore_order) for pred_vec in t_pred_list):
            return 0
    return 1


def run_sql(timeout=600):
    cred = json.load(open(CRED_PATH))
    kwargs = {k: v for k, v in cred.items() if k != "session_parameters"}
    account = kwargs.get("account", "")
    if account.endswith(".snowflakecomputing.com"):
        kwargs["account"] = account.removesuffix(".snowflakecomputing.com")
    session_parameters = cred.get("session_parameters", {}).copy()
    session_parameters["STATEMENT_TIMEOUT_IN_SECONDS"] = timeout
    kwargs["session_parameters"] = session_parameters

    sql = open(SQL_PATH).read()
    conn = snowflake.connector.connect(database="IDC", **kwargs)
    cur = conn.cursor()
    try:
        print(f"Running SQL (timeout={timeout}s)...")
        cur.execute(sql)
        df = pd.DataFrame(cur.fetchall(), columns=[d[0] for d in cur.description])
        df.to_csv(OUT_PATH, index=False)
        print(f"Saved {len(df)} rows -> {OUT_PATH}")
        return df
    finally:
        cur.close()
        conn.close()


def evaluate(df):
    print(f"\nResult rows: {len(df)}")
    print(f"Columns: {list(df.columns)}")
    print(f"SOP>=3: {len(df[df.iloc[:, 5] >= 3])}")
    print(f"Tolerance>0: {len(df[df.iloc[:, 9] > 0])}")

    for label in ["a", "b", "c", "d", "e", "f"]:
        path = os.path.join(GOLD_DIR, f"sf_bq069_{label}.csv")
        if not os.path.exists(path):
            continue
        gold = pd.read_csv(path)
        score14 = compare_pandas_table(df, gold, condition_cols=[14], ignore_order=True)
        score_all = compare_pandas_table(df, gold, condition_cols=[], ignore_order=True)
        print(f"gold_{label}: rows={len(gold)} | col14={score14} | all_cols={score_all}")


if __name__ == "__main__":
    if os.path.exists(OUT_PATH) and "--skip-run" in sys.argv:
        df = pd.read_csv(OUT_PATH)
    else:
        df = run_sql()
    evaluate(df)
