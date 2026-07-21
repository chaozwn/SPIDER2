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


def check(df, title):
    print(f"\n=== {title} ===")
    print(df.to_string(index=False))
    for col in df.columns:
        for v in df[col].tolist():
            try:
                fv = float(v)
                if abs(fv - TARGET) < 1e-10 or abs(fv + TARGET) < 1e-10:
                    print(f"*** EXACT MATCH {col}={v}")
                elif abs(abs(fv) - TARGET) < 1e-5:
                    print(f"** NEAR {col}={v}")
            except Exception:
                pass


def main():
    conn = connect()
    cur = conn.cursor()
    try:
        cur.execute(
            '''
            WITH t AS (
              SELECT LEFT("TargetCompID",4) p,
                     "Sides"[0]:Side::STRING side,
                     "StrikePrice"-"LastPx" iv,
                     ("StrikePrice"-"LastPx")*IFF("Sides"[0]:Side::STRING='LONG',1,-1) pnl
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
            )
            SELECT
              AVG(IFF(p='PRED' AND side='LONG', iv, NULL))
                - AVG(IFF(p='MOMO' AND side='LONG', iv, NULL)) AS pred_minus_momo_long,
              AVG(IFF(p='LUCK' AND side='LONG', pnl, NULL))
                - AVG(IFF(p='MOMO' AND side='LONG', pnl, NULL)) AS luck_momo_pnl,
              AVG(IFF(p='LUCK', pnl, NULL))
                - AVG(IFF(p='MOMO', pnl, NULL)) AS luck_momo_pnl_all,
              AVG(IFF(p='LUCK' AND side='LONG', iv, NULL)) AS luck_long,
              AVG(IFF(p='MOMO' AND side='LONG', iv, NULL)) AS momo_long,
              AVG(IFF(p='PRED' AND side='LONG', iv, NULL)) AS pred_long,
              AVG(IFF(p='LUCK' AND side='SHORT', iv, NULL))
                - AVG(IFF(p='MOMO' AND side='SHORT', iv, NULL)) AS luck_momo_short,
              AVG(IFF(p='LUCK' AND side='LONG', ABS(iv), NULL)) AS luck_abs,
              AVG(IFF(p='MOMO' AND side='LONG', ABS(iv), NULL)) AS momo_abs,
              AVG(IFF(p='MOMO' AND side='LONG', ABS(iv), NULL))
                - AVG(IFF(p='LUCK' AND side='LONG', ABS(iv), NULL)) AS abs_momo_minus_luck
            FROM t
            '''
        )
        df = pd.DataFrame(cur.fetchall(), columns=[d[0] for d in cur.description])
        check(df, "more combos")

        # Per TradeDate average of daily diffs, then avg
        cur.execute(
            '''
            WITH t AS (
              SELECT "TradeDate" d, LEFT("TargetCompID",4) p, "StrikePrice"-"LastPx" iv
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
              WHERE "Sides"[0]:Side::STRING='LONG' AND LEFT("TargetCompID",4) IN ('LUCK','MOMO')
            ),
            daily AS (
              SELECT d,
                AVG(IFF(p='LUCK',iv,NULL)) luck,
                AVG(IFF(p='MOMO',iv,NULL)) momo
              FROM t GROUP BY d
            )
            SELECT AVG(luck-momo) avg_daily_diff, AVG(momo-luck) flip,
                   MEDIAN(luck-momo) med_daily, COUNT(*) days
            FROM daily WHERE luck IS NOT NULL AND momo IS NOT NULL
            '''
        )
        df = pd.DataFrame(cur.fetchall(), columns=[d[0] for d in cur.description])
        check(df, "daily diffs")

        # Maybe they used MAX-MIN or something
        cur.execute(
            '''
            WITH t AS (
              SELECT LEFT("TargetCompID",4) p, "StrikePrice"-"LastPx" iv
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
              WHERE "Sides"[0]:Side::STRING='LONG' AND LEFT("TargetCompID",4) IN ('LUCK','MOMO')
            )
            SELECT
              MAX(IFF(p='LUCK',iv,NULL))-MAX(IFF(p='MOMO',iv,NULL)) max_diff,
              MIN(IFF(p='LUCK',iv,NULL))-MIN(IFF(p='MOMO',iv,NULL)) min_diff,
              AVG(IFF(p='LUCK',iv,NULL))-MIN(IFF(p='MOMO',iv,NULL)) weird1,
              MAX(IFF(p='LUCK',iv,NULL))-AVG(IFF(p='MOMO',iv,NULL)) weird2
            FROM t
            '''
        )
        df = pd.DataFrame(cur.fetchall(), columns=[d[0] for d in cur.description])
        check(df, "max/min weird")

        # Return * 10000 or dollar? try (close-open)/open averaged then * something
        # Or SUM of iv / number of strategies
        cur.execute(
            '''
            WITH t AS (
              SELECT LEFT("TargetCompID",4) p, "Symbol" s, "StrikePrice"-"LastPx" iv
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
              WHERE "Sides"[0]:Side::STRING='LONG' AND LEFT("TargetCompID",4) IN ('LUCK','MOMO')
            ),
            per AS (
              SELECT s, AVG(IFF(p='LUCK',iv,NULL))-AVG(IFF(p='MOMO',iv,NULL)) d
              FROM t GROUP BY s
            )
            SELECT d, s FROM per ORDER BY ABS(ABS(d) - 0.27640950080146753) ASC LIMIT 10
            '''
        )
        df = pd.DataFrame(cur.fetchall(), columns=[d[0] for d in cur.description])
        check(df, "closest symbol diffs")

        # Weighted by count of momo or luck
        cur.execute(
            '''
            WITH t AS (
              SELECT "Symbol" s, LEFT("TargetCompID",4) p, "StrikePrice"-"LastPx" iv
              FROM CYMBAL_INVESTMENTS.TRADE_CAPTURE_REPORT
              WHERE "Sides"[0]:Side::STRING='LONG' AND LEFT("TargetCompID",4) IN ('LUCK','MOMO')
            ),
            per AS (
              SELECT s,
                AVG(IFF(p='LUCK',iv,NULL)) luck,
                AVG(IFF(p='MOMO',iv,NULL)) momo,
                COUNT(IFF(p='LUCK',1,NULL)) lc,
                COUNT(IFF(p='MOMO',1,NULL)) mc
              FROM t GROUP BY s
            )
            SELECT
              SUM((luck-momo)*lc)/SUM(lc) w_luck,
              SUM((luck-momo)*mc)/SUM(mc) w_momo,
              SUM((luck-momo)*(lc+mc))/SUM(lc+mc) w_both,
              SUM((momo-luck)*lc)/SUM(lc) wf_luck,
              SUM((momo-luck)*mc)/SUM(mc) wf_momo
            FROM per WHERE luck IS NOT NULL AND momo IS NOT NULL
            '''
        )
        df = pd.DataFrame(cur.fetchall(), columns=[d[0] for d in cur.description])
        check(df, "weighted symbol diffs")
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
