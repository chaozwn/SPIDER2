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
    # highlight near target
    for col in df.columns:
        for v in df[col].tolist():
            try:
                if abs(float(v) - TARGET) < 1e-6 or abs(float(v) + TARGET) < 1e-6:
                    print(f"*** MATCH on {col}={v}")
            except Exception:
                pass
    return df


def main():
    conn = connect()
    cur = conn.cursor()
    try:
        # SHORT side
        run(
            cur,
            '''
            WITH t AS (
              SELECT LEFT("TargetCompID",4) p, "StrikePrice"-"LastPx" iv
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
              WHERE "Sides"[0]:Side::STRING='SHORT' AND LEFT("TargetCompID",4) IN ('LUCK','MOMO')
            )
            SELECT AVG(IFF(p='LUCK',iv,NULL))-AVG(IFF(p='MOMO',iv,NULL)) d1,
                   AVG(IFF(p='MOMO',iv,NULL))-AVG(IFF(p='LUCK',iv,NULL)) d2,
                   AVG(IFF(p='LUCK',ABS(iv),NULL))-AVG(IFF(p='MOMO',ABS(iv),NULL)) d3
            FROM t
            ''',
            "SHORT side",
        )

        # AVG of LastPx / StrikePrice alone
        run(
            cur,
            '''
            WITH t AS (
              SELECT LEFT("TargetCompID",4) p, "LastPx" o, "StrikePrice" c
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
              WHERE "Sides"[0]:Side::STRING='LONG' AND LEFT("TargetCompID",4) IN ('LUCK','MOMO')
            )
            SELECT
              AVG(IFF(p='LUCK',o,NULL))-AVG(IFF(p='MOMO',o,NULL)) open_diff,
              AVG(IFF(p='LUCK',c,NULL))-AVG(IFF(p='MOMO',c,NULL)) close_diff,
              AVG(IFF(p='LUCK',c/o,NULL))-AVG(IFF(p='MOMO',c/o,NULL)) ratio_diff,
              AVG(IFF(p='LUCK',o/c,NULL))-AVG(IFF(p='MOMO',o/c,NULL)) inv_ratio_diff
            FROM t
            ''',
            "price level diffs LONG",
        )

        # Per-symbol then average? or only specific symbols
        run(
            cur,
            '''
            WITH t AS (
              SELECT "Symbol" sym, LEFT("TargetCompID",4) p, "StrikePrice"-"LastPx" iv
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
              WHERE "Sides"[0]:Side::STRING='LONG' AND LEFT("TargetCompID",4) IN ('LUCK','MOMO')
            ),
            per AS (
              SELECT sym,
                AVG(IFF(p='LUCK',iv,NULL)) luck,
                AVG(IFF(p='MOMO',iv,NULL)) momo
              FROM t GROUP BY sym
            )
            SELECT AVG(luck-momo) avg_of_sym_diff, AVG(momo-luck) flip,
                   LISTAGG(sym||':'||ROUND(luck-momo,6), ', ') WITHIN GROUP (ORDER BY sym) details
            FROM per WHERE luck IS NOT NULL AND momo IS NOT NULL
            ''',
            "per-symbol then avg",
        )

        # MEDIAN difference
        run(
            cur,
            '''
            WITH t AS (
              SELECT LEFT("TargetCompID",4) p, "StrikePrice"-"LastPx" iv
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
              WHERE "Sides"[0]:Side::STRING='LONG' AND LEFT("TargetCompID",4) IN ('LUCK','MOMO')
            )
            SELECT
              MEDIAN(IFF(p='LUCK',iv,NULL))-MEDIAN(IFF(p='MOMO',iv,NULL)) med_diff,
              MEDIAN(IFF(p='MOMO',iv,NULL))-MEDIAN(IFF(p='LUCK',iv,NULL)) med_flip
            FROM t
            ''',
            "median diff",
        )

        # STDDEV
        run(
            cur,
            '''
            WITH t AS (
              SELECT LEFT("TargetCompID",4) p, "StrikePrice"-"LastPx" iv
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
              WHERE "Sides"[0]:Side::STRING='LONG' AND LEFT("TargetCompID",4) IN ('LUCK','MOMO')
            )
            SELECT
              STDDEV(IFF(p='LUCK',iv,NULL))-STDDEV(IFF(p='MOMO',iv,NULL)) sd_diff,
              AVG(IFF(p='LUCK',iv,NULL)) luck_avg,
              AVG(IFF(p='MOMO',iv,NULL)) momo_avg,
              STDDEV(IFF(p='LUCK',iv,NULL)) luck_sd,
              STDDEV(IFF(p='MOMO',iv,NULL)) momo_sd
            FROM t
            ''',
            "stddev",
        )

        # Maybe TargetCompID contains full string like FEELING-LUCKY?
        run(
            cur,
            '''
            SELECT DISTINCT "TargetCompID"
            FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
            LIMIT 50
            ''',
            "sample TargetCompID",
        )

        # Try PartyID LUCKY* vs MOMO* with LONG
        run(
            cur,
            '''
            WITH t AS (
              SELECT
                LEFT(s.value:PartyIDs[0]:PartyID::STRING, 4) p,
                t."StrikePrice" - t."LastPx" iv
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT t,
              LATERAL FLATTEN(input => t."Sides") s
              WHERE s.value:Side::STRING='LONG'
                AND LEFT(s.value:PartyIDs[0]:PartyID::STRING, 4) IN ('LUCK','MOMO')
            )
            SELECT AVG(IFF(p='LUCK',iv,NULL))-AVG(IFF(p='MOMO',iv,NULL)) d1,
                   AVG(IFF(p='MOMO',iv,NULL))-AVG(IFF(p='LUCK',iv,NULL)) d2
            FROM t
            ''',
            "PartyID based LONG",
        )

        # PnL with multiplier on LONG only should be same
        # What about (LastPx - StrikePrice) * Quantity for long?
        run(
            cur,
            '''
            WITH t AS (
              SELECT LEFT("TargetCompID",4) p,
                     ("LastPx"-"StrikePrice")*"Quantity" iv
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
              WHERE "Sides"[0]:Side::STRING='LONG' AND LEFT("TargetCompID",4) IN ('LUCK','MOMO')
            )
            SELECT AVG(IFF(p='LUCK',iv,NULL))-AVG(IFF(p='MOMO',iv,NULL)) d1,
                   AVG(IFF(p='MOMO',iv,NULL))-AVG(IFF(p='LUCK',iv,NULL)) d2
            FROM t
            ''',
            "open-close * qty LONG",
        )
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
