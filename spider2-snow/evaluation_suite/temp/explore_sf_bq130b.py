#!/usr/bin/env python3
"""Try multiple SQL variants to match sf_bq130 gold CSVs."""
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
GOLD_DIR = os.path.join(SUITE_DIR, "gold", "exec_result")


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


def run(cur, sql):
    cur.execute(sql)
    cols = [d[0].lower() for d in cur.description]
    return pd.DataFrame(cur.fetchall(), columns=cols)


def make_state_sql(new_case_expr, rank_fn, date_start, date_end, extra_where="", limit=5):
    return f'''
WITH daily AS (
  SELECT
    "date",
    "state_name",
    {new_case_expr} AS new_cases
  FROM COVID19_NYT.COVID19_NYT.US_STATES
),
filtered AS (
  SELECT * FROM daily
  WHERE "date" BETWEEN '{date_start}' AND '{date_end}'
    AND new_cases IS NOT NULL
    {extra_where}
),
ranked AS (
  SELECT *,
    {rank_fn}() OVER (PARTITION BY "date" ORDER BY new_cases DESC) AS rnk
  FROM filtered
),
top5 AS (
  SELECT * FROM ranked WHERE rnk <= 5
),
freq AS (
  SELECT "state_name", COUNT(*) AS freq
  FROM top5
  GROUP BY 1
)
SELECT "state_name", freq,
  ROW_NUMBER() OVER (ORDER BY freq DESC, "state_name") AS rank
FROM freq
ORDER BY rank
LIMIT {limit}
'''


def make_county_sql(new_case_expr, rank_fn, date_start, date_end, state="Illinois", extra_where="", limit=5):
    return f'''
WITH daily AS (
  SELECT
    "date",
    "county",
    {new_case_expr} AS new_cases
  FROM COVID19_NYT.COVID19_NYT.US_COUNTIES
  WHERE "state_name" = '{state}'
),
filtered AS (
  SELECT * FROM daily
  WHERE "date" BETWEEN '{date_start}' AND '{date_end}'
    AND new_cases IS NOT NULL
    {extra_where}
),
ranked AS (
  SELECT *,
    {rank_fn}() OVER (PARTITION BY "date" ORDER BY new_cases DESC) AS rnk
  FROM filtered
),
top5 AS (
  SELECT * FROM ranked WHERE rnk <= 5
),
freq AS (
  SELECT "county", COUNT(*) AS freq
  FROM top5
  GROUP BY 1
)
SELECT "county", freq,
  ROW_NUMBER() OVER (ORDER BY freq DESC, "county") AS rank
FROM freq
ORDER BY rank
LIMIT {limit}
'''


LAG_DIFF = '("confirmed_cases" - LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date"))'
LAG_DIFF_C = '("confirmed_cases" - LAG("confirmed_cases") OVER (PARTITION BY "state_name", "county" ORDER BY "date"))'
LAG_COALESCE = '("confirmed_cases" - COALESCE(LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date"), 0))'
LAG_COALESCE_C = '("confirmed_cases" - COALESCE(LAG("confirmed_cases") OVER (PARTITION BY "state_name", "county" ORDER BY "date"), 0))'
GREATEST0 = f'GREATEST(0, {LAG_DIFF})'
GREATEST0_C = f'GREATEST(0, {LAG_DIFF_C})'
GREATEST0_COAL = f'GREATEST(0, {LAG_COALESCE})'
GREATEST0_COAL_C = f'GREATEST(0, {LAG_COALESCE_C})'


VARIANTS = [
    ("lag_null_rn_mar1", LAG_DIFF, LAG_DIFF_C, "ROW_NUMBER", "2020-03-01", "2020-05-31", "", ""),
    ("lag_coal_rn_mar1", LAG_COALESCE, LAG_COALESCE_C, "ROW_NUMBER", "2020-03-01", "2020-05-31", "", ""),
    ("lag_g0_rn_mar1", GREATEST0, GREATEST0_C, "ROW_NUMBER", "2020-03-01", "2020-05-31", "", ""),
    ("lag_g0c_rn_mar1", GREATEST0_COAL, GREATEST0_COAL_C, "ROW_NUMBER", "2020-03-01", "2020-05-31", "", ""),
    ("lag_null_rank_mar1", LAG_DIFF, LAG_DIFF_C, "RANK", "2020-03-01", "2020-05-31", "", ""),
    ("lag_coal_rank_mar1", LAG_COALESCE, LAG_COALESCE_C, "RANK", "2020-03-01", "2020-05-31", "", ""),
    ("lag_null_rn_mar2", LAG_DIFF, LAG_DIFF_C, "ROW_NUMBER", "2020-03-02", "2020-05-31", "", ""),
    ("lag_null_rn_gt0", LAG_DIFF, LAG_DIFF_C, "ROW_NUMBER", "2020-03-01", "2020-05-31", "AND new_cases > 0", "AND new_cases > 0"),
    ("lag_coal_rn_gt0", LAG_COALESCE, LAG_COALESCE_C, "ROW_NUMBER", "2020-03-01", "2020-05-31", "AND new_cases > 0", "AND new_cases > 0"),
    ("lag_null_rn_ge0", LAG_DIFF, LAG_DIFF_C, "ROW_NUMBER", "2020-03-01", "2020-05-31", "AND new_cases >= 0", "AND new_cases >= 0"),
    ("lag_null_rn_unk", LAG_DIFF, LAG_DIFF_C, "ROW_NUMBER", "2020-03-01", "2020-05-31", "", "AND \"county\" <> 'Unknown'"),
    ("lag_coal_rn_unk", LAG_COALESCE, LAG_COALESCE_C, "ROW_NUMBER", "2020-03-01", "2020-05-31", "", "AND \"county\" <> 'Unknown'"),
    ("lag_null_rn_unk_gt0", LAG_DIFF, LAG_DIFF_C, "ROW_NUMBER", "2020-03-01", "2020-05-31", "AND new_cases > 0", "AND new_cases > 0 AND \"county\" <> 'Unknown'"),
    ("lag_coal_rn_unk_gt0", LAG_COALESCE, LAG_COALESCE_C, "ROW_NUMBER", "2020-03-01", "2020-05-31", "AND new_cases > 0", "AND new_cases > 0 AND \"county\" <> 'Unknown'"),
    ("lag_null_dense_mar1", LAG_DIFF, LAG_DIFF_C, "DENSE_RANK", "2020-03-01", "2020-05-31", "", ""),
    ("lag_coal_dense_mar1", LAG_COALESCE, LAG_COALESCE_C, "DENSE_RANK", "2020-03-01", "2020-05-31", "", ""),
]


TARGETS = {
    "a": {"states": [("New York", 90), ("California", 69), ("New Jersey", 65), ("Illinois", 54), ("Massachusetts", 50)],
          "counties": [("Cook", 87), ("Lake", 77), ("DuPage", 75), ("Kane", 67), ("Will", 63)]},
    "c": {"states": [("New York", 89), ("California", 70), ("New Jersey", 63), ("Illinois", 55), ("Massachusetts", 50)],
          "counties": [("Cook", 92), ("Lake", 79), ("DuPage", 76), ("Kane", 70), ("Will", 62)]},
    "d_states": {"states": [("New York", 89), ("California", 69), ("New Jersey", 65), ("Illinois", 54), ("Massachusetts", 50)]},
    "d_counties": {"counties": [("Cook", 87), ("Lake", 77), ("DuPage", 75), ("Kane", 67), ("Will", 62)]},
    "e": {"states": [("New York", 90), ("California", 70), ("New Jersey", 64), ("Illinois", 54), ("Massachusetts", 50)],
          "counties": [("Cook", 91), ("Lake", 78), ("DuPage", 76), ("Kane", 69), ("Will", 62)]},
}


def match_states(df, expected):
    got = [(r["state_name"], int(r["freq"])) for _, r in df.iterrows()]
    return got == expected


def match_counties(df, expected):
    got = [(r["county"], int(r["freq"])) for _, r in df.iterrows()]
    return got == expected


def main():
    conn = connect()
    cur = conn.cursor()

    for name, s_expr, c_expr, rfn, ds, de, sw, cw in VARIANTS:
        sdf = run(cur, make_state_sql(s_expr, rfn, ds, de, sw, limit=5))
        cdf = run(cur, make_county_sql(c_expr, rfn, ds, de, extra_where=cw, limit=5))
        print(f"\n=== {name} ===")
        print("STATES:", list(zip(sdf["state_name"], sdf["freq"].astype(int))))
        print("COUNTIES:", list(zip(cdf["county"], cdf["freq"].astype(int))))
        for tname, tgt in TARGETS.items():
            ok_s = ("states" not in tgt) or match_states(sdf, tgt["states"])
            ok_c = ("counties" not in tgt) or match_counties(cdf, tgt["counties"])
            if ok_s and ok_c:
                print(f"  >>> MATCHES {tname}")
            elif ok_s:
                print(f"  >>> STATES match {tname}")
            elif ok_c:
                print(f"  >>> COUNTIES match {tname}")

    conn.close()


if __name__ == "__main__":
    main()
