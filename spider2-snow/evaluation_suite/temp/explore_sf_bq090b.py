#!/usr/bin/env python3
import json
import os
import snowflake.connector
import pandas as pd

SUITE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO_ROOT = os.path.dirname(os.path.dirname(SUITE_DIR))
CRED_CANDIDATES = [
    os.path.join(SUITE_DIR, "snowflake_credential.json"),
    os.path.join(REPO_ROOT, "methods", "spider_agent_infini", "snowflake_credential.json"),
]
CRED_PATH = next(p for p in CRED_CANDIDATES if os.path.exists(p))
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
    return df


def main():
    conn = connect()
    cur = conn.cursor()
    try:
        # percent returns
        run(
            cur,
            '''
            WITH long_trades AS (
              SELECT
                LEFT(t."TargetCompID", 4) AS prefix,
                (t."StrikePrice" - t."LastPx") / NULLIF(t."LastPx", 0) AS iv,
                (t."StrikePrice" - t."LastPx") * t."Quantity" AS iv_qty,
                ABS(t."StrikePrice" - t."LastPx") AS iv_abs
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT t
              WHERE t."Sides"[0]:Side::STRING = 'LONG'
                AND LEFT(t."TargetCompID", 4) IN ('LUCK', 'MOMO')
            )
            SELECT
              AVG(IFF(prefix='LUCK', iv, NULL)) - AVG(IFF(prefix='MOMO', iv, NULL)) AS pct_diff,
              AVG(IFF(prefix='LUCK', iv_qty, NULL)) - AVG(IFF(prefix='MOMO', iv_qty, NULL)) AS qty_diff,
              AVG(IFF(prefix='LUCK', iv_abs, NULL)) - AVG(IFF(prefix='MOMO', iv_abs, NULL)) AS abs_diff,
              AVG(IFF(prefix='MOMO', iv, NULL)) - AVG(IFF(prefix='LUCK', iv, NULL)) AS pct_flip,
              AVG(IFF(prefix='MOMO', iv_qty, NULL)) - AVG(IFF(prefix='LUCK', iv_qty, NULL)) AS qty_flip,
              AVG(IFF(prefix='MOMO', iv_abs, NULL)) - AVG(IFF(prefix='LUCK', iv_abs, NULL)) AS abs_flip
            FROM long_trades
            ''',
            "pct / qty / abs diffs",
        )

        # SenderCompID instead of TargetCompID
        run(
            cur,
            '''
            SELECT LEFT("SenderCompID", 4) AS prefix, COUNT(*) cnt
            FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
            GROUP BY 1 ORDER BY cnt DESC LIMIT 20
            ''',
            "SenderCompID prefixes",
        )

        # PartyID based strategy
        run(
            cur,
            '''
            SELECT
              LEFT(s.value:PartyIDs[0]:PartyID::STRING, 4) AS party_prefix,
              s.value:PartyIDs[0]:PartyID::STRING AS party,
              COUNT(*) cnt
            FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT t,
            LATERAL FLATTEN(input => t."Sides") s
            GROUP BY 1, 2
            ORDER BY cnt DESC
            LIMIT 30
            ''',
            "PartyID values",
        )

        # Maybe intrinsic uses multiplier always: (close-open)*mult, and filter long
        # already same for LONG

        # Try ALL sides with multiplier, then only feeling lucky vs momentum
        run(
            cur,
            '''
            WITH trades AS (
              SELECT
                LEFT(t."TargetCompID", 4) AS prefix,
                (t."StrikePrice" - t."LastPx") *
                  IFF(t."Sides"[0]:Side::STRING = 'LONG', 1, -1) AS intrinsic
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT t
              WHERE LEFT(t."TargetCompID", 4) IN ('LUCK', 'MOMO')
            )
            SELECT
              AVG(IFF(prefix='LUCK', intrinsic, NULL)) AS luck,
              AVG(IFF(prefix='MOMO', intrinsic, NULL)) AS momo,
              AVG(IFF(prefix='LUCK', intrinsic, NULL)) - AVG(IFF(prefix='MOMO', intrinsic, NULL)) AS diff
            FROM trades
            ''',
            "All sides with multiplier",
        )

        # LONG only but using open-close with qty weighted avg?
        run(
            cur,
            '''
            WITH long_trades AS (
              SELECT
                LEFT(t."TargetCompID", 4) AS prefix,
                t."StrikePrice" - t."LastPx" AS iv,
                t."Quantity" AS qty
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT t
              WHERE t."Sides"[0]:Side::STRING = 'LONG'
                AND LEFT(t."TargetCompID", 4) IN ('LUCK', 'MOMO')
            )
            SELECT
              SUM(IFF(prefix='LUCK', iv*qty, 0))/NULLIF(SUM(IFF(prefix='LUCK', qty, 0)),0)
                - SUM(IFF(prefix='MOMO', iv*qty, 0))/NULLIF(SUM(IFF(prefix='MOMO', qty, 0)),0)
                AS weighted_diff
            FROM long_trades
            ''',
            "Quantity-weighted diff",
        )
    finally:
        cur.close()
        conn.close()
    print(f"\nTARGET gold abs value = {TARGET}")


if __name__ == "__main__":
    main()
