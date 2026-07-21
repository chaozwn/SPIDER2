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
        run(
            cur,
            '''
            SELECT LEFT("TargetCompID", 4) AS prefix, COUNT(*) AS cnt
            FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
            GROUP BY 1 ORDER BY cnt DESC
            ''',
            "TargetCompID prefixes",
        )

        run(
            cur,
            '''
            SELECT s.value:Side::STRING AS side, COUNT(*) AS cnt
            FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT t,
            LATERAL FLATTEN(input => t."Sides") s
            GROUP BY 1
            ''',
            "Side values",
        )

        run(
            cur,
            '''
            SELECT
              LEFT(t."TargetCompID", 4) AS prefix,
              s.value:Side::STRING AS side,
              AVG(t."StrikePrice" - t."LastPx") AS avg_close_minus_open,
              AVG(t."LastPx" - t."StrikePrice") AS avg_open_minus_close,
              COUNT(*) AS cnt
            FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT t,
            LATERAL FLATTEN(input => t."Sides") s
            WHERE s.value:Side::STRING = 'LONG'
            GROUP BY 1, 2
            ORDER BY 1
            ''',
            "LONG averages by strategy prefix",
        )

        # Try without flatten - Sides[0]
        run(
            cur,
            '''
            WITH long_trades AS (
              SELECT
                LEFT(t."TargetCompID", 4) AS prefix,
                t."StrikePrice" - t."LastPx" AS intrinsic_value
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT t
              WHERE t."Sides"[0]:Side::STRING = 'LONG'
                AND LEFT(t."TargetCompID", 4) IN ('LUCK', 'MOMO')
            )
            SELECT
              AVG(IFF(prefix = 'LUCK', intrinsic_value, NULL)) AS luck_avg,
              AVG(IFF(prefix = 'MOMO', intrinsic_value, NULL)) AS momo_avg,
              AVG(IFF(prefix = 'LUCK', intrinsic_value, NULL))
                - AVG(IFF(prefix = 'MOMO', intrinsic_value, NULL))
                AS avg_intrinsic_value_difference,
              AVG(IFF(prefix = 'MOMO', intrinsic_value, NULL))
                - AVG(IFF(prefix = 'LUCK', intrinsic_value, NULL))
                AS difference
            FROM long_trades
            ''',
            "Diff close-open via Sides[0]",
        )

        run(
            cur,
            '''
            WITH long_trades AS (
              SELECT
                LEFT(t."TargetCompID", 4) AS prefix,
                t."StrikePrice" - t."LastPx" AS intrinsic_value
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT t,
              LATERAL FLATTEN(input => t."Sides") s
              WHERE s.value:Side::STRING = 'LONG'
                AND LEFT(t."TargetCompID", 4) IN ('LUCK', 'MOMO')
            )
            SELECT
              AVG(IFF(prefix = 'LUCK', intrinsic_value, NULL)) AS luck_avg,
              AVG(IFF(prefix = 'MOMO', intrinsic_value, NULL)) AS momo_avg,
              AVG(IFF(prefix = 'LUCK', intrinsic_value, NULL))
                - AVG(IFF(prefix = 'MOMO', intrinsic_value, NULL))
                AS avg_intrinsic_value_difference,
              AVG(IFF(prefix = 'MOMO', intrinsic_value, NULL))
                - AVG(IFF(prefix = 'LUCK', intrinsic_value, NULL))
                AS difference
            FROM long_trades
            ''',
            "Diff close-open via FLATTEN",
        )
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
