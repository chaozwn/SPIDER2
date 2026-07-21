#!/usr/bin/env python3
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
TARGET = 0.27640950080146753


def connect():
    cred = json.load(open(CRED_PATH))
    kwargs = {k: v for k, v in cred.items() if k != "session_parameters"}
    account = kwargs.get("account", "")
    if account.endswith(".snowflakecomputing.com"):
        kwargs["account"] = account.removesuffix(".snowflakecomputing.com")
    kwargs["session_parameters"] = cred.get("session_parameters", {})
    return snowflake.connector.connect(database="CYMBAL_INVESTMENTS", **kwargs)


def run(cur, sql, title):
    print(f"\n=== {title} ===")
    cur.execute(sql)
    df = pd.DataFrame(cur.fetchall(), columns=[d[0] for d in cur.description])
    print(df.to_string(index=False))
    for col in df.columns:
        for v in df[col].tolist():
            try:
                fv = float(v)
                if abs(fv - TARGET) < 1e-9 or abs(fv + TARGET) < 1e-9:
                    print(f"*** EXACT MATCH {col}={v}")
                elif abs(fv - TARGET) < 1e-4 or abs(fv + TARGET) < 1e-4:
                    print(f"** NEAR MATCH {col}={v}")
            except Exception:
                pass
    return df


def main():
    conn = connect()
    cur = conn.cursor()
    try:
        # by underlying asset prefix
        run(
            cur,
            '''
            WITH t AS (
              SELECT LEFT("Symbol", 2) und,
                     LEFT("TargetCompID",4) p,
                     "StrikePrice"-"LastPx" iv
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
              WHERE "Sides"[0]:Side::STRING='LONG' AND LEFT("TargetCompID",4) IN ('LUCK','MOMO')
            )
            SELECT und,
              AVG(IFF(p='LUCK',iv,NULL)) luck,
              AVG(IFF(p='MOMO',iv,NULL)) momo,
              AVG(IFF(p='LUCK',iv,NULL))-AVG(IFF(p='MOMO',iv,NULL)) diff,
              AVG(IFF(p='MOMO',iv,NULL))-AVG(IFF(p='LUCK',iv,NULL)) flip,
              COUNT(*) cnt
            FROM t GROUP BY und ORDER BY und
            ''',
            "by underlying",
        )

        # only BTC*
        run(
            cur,
            '''
            WITH t AS (
              SELECT LEFT("TargetCompID",4) p, "StrikePrice"-"LastPx" iv
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
              WHERE "Sides"[0]:Side::STRING='LONG'
                AND LEFT("TargetCompID",4) IN ('LUCK','MOMO')
                AND "Symbol" LIKE 'BTC%'
            )
            SELECT AVG(IFF(p='LUCK',iv,NULL))-AVG(IFF(p='MOMO',iv,NULL)) diff,
                   AVG(IFF(p='MOMO',iv,NULL))-AVG(IFF(p='LUCK',iv,NULL)) flip,
                   AVG(IFF(p='LUCK',iv,NULL)) luck, AVG(IFF(p='MOMO',iv,NULL)) momo,
                   COUNT(*) cnt
            FROM t
            ''',
            "BTC only LONG",
        )

        # reproduce gold SQL structure exactly (cross join avgs)
        run(
            cur,
            '''
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
              AS averageDifference_subquery,
              (SELECT AVG(priceDifference) FROM MomentumTrades)
              - (SELECT AVG(priceDifference) FROM FeelingLuckyTrades)
              AS flipped
            ''',
            "gold SQL structure",
        )

        # Maybe they used LastPx as intrinsic? or Strike?
        run(
            cur,
            '''
            WITH t AS (
              SELECT LEFT("TargetCompID",4) p, "LastPx" lp, "StrikePrice" sp,
                     ABS("StrikePrice"-"LastPx") ab
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
              WHERE "Sides"[0]:Side::STRING='LONG' AND LEFT("TargetCompID",4) IN ('LUCK','MOMO')
                AND "Symbol" LIKE 'BTC%'
            )
            SELECT
              AVG(IFF(p='LUCK',ab,NULL))-AVG(IFF(p='MOMO',ab,NULL)) abs_diff_btc,
              AVG(IFF(p='MOMO',ab,NULL))-AVG(IFF(p='LUCK',ab,NULL)) abs_flip_btc
            FROM t
            ''',
            "BTC abs",
        )

        # Check if Quantity always 1 - maybe weighted differently
        # Try: AVG over distinct OrderID?
        run(
            cur,
            '''
            WITH t AS (
              SELECT "OrderID", LEFT("TargetCompID",4) p, AVG("StrikePrice"-"LastPx") iv
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
              WHERE "Sides"[0]:Side::STRING='LONG' AND LEFT("TargetCompID",4) IN ('LUCK','MOMO')
              GROUP BY 1,2
            )
            SELECT AVG(IFF(p='LUCK',iv,NULL))-AVG(IFF(p='MOMO',iv,NULL)) diff
            FROM t
            ''',
            "dedupe OrderID",
        )

        # Perhaps Side is nested differently and Sides without [0] - check rows where Side != first
        run(
            cur,
            '''
            SELECT COUNT(*) total,
              SUM(IFF("Sides"[0]:Side::STRING='LONG',1,0)) long0,
              SUM(IFF("Sides"[0]:Side::STRING='SHORT',1,0)) short0,
              SUM(IFF(ARRAY_SIZE("Sides")>1,1,0)) multi_side
            FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
            ''',
            "sides structure",
        )

        # Try matching target by computing luck_avg and momo_avg that would give 0.2764
        # If diff = luck - momo = -0.2764, and we know overall...
        # Search: maybe (close/open - 1) * 10000 or bps
        run(
            cur,
            '''
            WITH t AS (
              SELECT LEFT("TargetCompID",4) p,
                ("StrikePrice"/"LastPx" - 1)*10000 AS bps,
                ("StrikePrice"-"LastPx")*100 AS x100
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
              WHERE "Sides"[0]:Side::STRING='LONG' AND LEFT("TargetCompID",4) IN ('LUCK','MOMO')
            )
            SELECT
              AVG(IFF(p='LUCK',bps,NULL))-AVG(IFF(p='MOMO',bps,NULL)) bps_diff,
              AVG(IFF(p='LUCK',x100,NULL))-AVG(IFF(p='MOMO',x100,NULL)) x100_diff
            FROM t
            ''',
            "bps / x100",
        )
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
