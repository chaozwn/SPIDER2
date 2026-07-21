#!/usr/bin/env python3
"""Final verification: official gold SQL adapted to Snowflake vs gold CSV."""
import json
import math
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
GOLD_A = os.path.join(SUITE_DIR, "gold", "exec_result", "sf_bq090_a.csv")
GOLD_B = os.path.join(SUITE_DIR, "gold", "exec_result", "sf_bq090_b.csv")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sf_bq090_verified.csv")

# Snowflake adaptation of official spider2-lite gold/sql/bq090.sql
SQL_A = '''
WITH MomentumTrades AS (
  SELECT "StrikePrice" - "LastPx" AS priceDifference
  FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
  WHERE LEFT("TargetCompID", 4) = 'MOMO'
    AND "Sides"[0]:Side::STRING = 'LONG'
),
FeelingLuckyTrades AS (
  SELECT "StrikePrice" - "LastPx" AS priceDifference
  FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
  WHERE LEFT("TargetCompID", 4) = 'LUCK'
    AND "Sides"[0]:Side::STRING = 'LONG'
)
SELECT
  (SELECT AVG(priceDifference) FROM FeelingLuckyTrades)
  - (SELECT AVG(priceDifference) FROM MomentumTrades)
  AS AVG_INTRINSIC_VALUE_DIFFERENCE
'''

SQL_B = '''
WITH MomentumTrades AS (
  SELECT "StrikePrice" - "LastPx" AS priceDifference
  FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
  WHERE LEFT("TargetCompID", 4) = 'MOMO'
    AND "Sides"[0]:Side::STRING = 'LONG'
),
FeelingLuckyTrades AS (
  SELECT "StrikePrice" - "LastPx" AS priceDifference
  FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
  WHERE LEFT("TargetCompID", 4) = 'LUCK'
    AND "Sides"[0]:Side::STRING = 'LONG'
)
SELECT
  (SELECT AVG(priceDifference) FROM MomentumTrades)
  - (SELECT AVG(priceDifference) FROM FeelingLuckyTrades)
  AS DIFFERENCE
'''


def connect():
    cred = json.load(open(CRED_PATH))
    kwargs = {k: v for k, v in cred.items() if k != "session_parameters"}
    account = kwargs.get("account", "")
    if account.endswith(".snowflakecomputing.com"):
        kwargs["account"] = account.removesuffix(".snowflakecomputing.com")
    kwargs["session_parameters"] = cred.get("session_parameters", {})
    return snowflake.connector.connect(database="CYMBAL_INVESTMENTS", **kwargs)


def run(cur, sql):
    cur.execute(sql)
    return pd.DataFrame(cur.fetchall(), columns=[d[0] for d in cur.description])


def main():
    conn = connect()
    cur = conn.cursor()
    try:
        df_a = run(cur, SQL_A)
        df_b = run(cur, SQL_B)
        print("SQL_A result:")
        print(df_a.to_string(index=False))
        print("SQL_B result:")
        print(df_b.to_string(index=False))

        gold_a = pd.read_csv(GOLD_A)
        gold_b = pd.read_csv(GOLD_B)
        print("\nGold A:")
        print(gold_a.to_string(index=False))
        print("Gold B:")
        print(gold_b.to_string(index=False))

        pred = float(df_a.iloc[0, 0])
        ga = float(gold_a.iloc[0, 0])
        gb = float(gold_b.iloc[0, 0])
        print(f"\npred={pred}")
        print(f"match gold_a? {math.isclose(pred, ga, abs_tol=1e-6)}")
        print(f"match gold_b? {math.isclose(pred, gb, abs_tol=1e-6)}")
        print(f"match -gold_a? {math.isclose(pred, -ga, abs_tol=1e-6)}")
        print(f"example_submission-like 0.023069? {math.isclose(pred, 0.023069449773148013, abs_tol=1e-9)}")

        df_a.to_csv(OUT, index=False)
        print(f"Saved {OUT}")
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
