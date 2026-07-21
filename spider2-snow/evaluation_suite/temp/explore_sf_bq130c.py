#!/usr/bin/env python3
"""More fine-grained variants for sf_bq130."""
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


def state_sql(new_expr, order_by, filter_clause, date_start="2020-03-01", date_end="2020-05-31", limit=5):
    return f'''
WITH daily AS (
  SELECT "date", "state_name",
    {new_expr} AS new_cases
  FROM COVID19_NYT.COVID19_NYT.US_STATES
),
filtered AS (
  SELECT * FROM daily
  WHERE "date" BETWEEN '{date_start}' AND '{date_end}'
    {filter_clause}
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY {order_by}) AS rnk
  FROM filtered
)
SELECT "state_name", COUNT(*) AS freq
FROM ranked WHERE rnk <= 5
GROUP BY 1
ORDER BY freq DESC, "state_name"
LIMIT {limit}
'''


def county_sql(new_expr, order_by, filter_clause, date_start="2020-03-01", date_end="2020-05-31", limit=5):
    return f'''
WITH daily AS (
  SELECT "date", "county",
    {new_expr} AS new_cases
  FROM COVID19_NYT.COVID19_NYT.US_COUNTIES
  WHERE "state_name" = 'Illinois'
),
filtered AS (
  SELECT * FROM daily
  WHERE "date" BETWEEN '{date_start}' AND '{date_end}'
    {filter_clause}
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY {order_by}) AS rnk
  FROM filtered
)
SELECT "county", COUNT(*) AS freq
FROM ranked WHERE rnk <= 5
GROUP BY 1
ORDER BY freq DESC, "county"
LIMIT {limit}
'''


S_LAG = '"confirmed_cases" - LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date")'
C_LAG = '"confirmed_cases" - LAG("confirmed_cases") OVER (PARTITION BY "state_name", "county" ORDER BY "date")'
S_COAL = '"confirmed_cases" - COALESCE(LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date"), 0)'
C_COAL = '"confirmed_cases" - COALESCE(LAG("confirmed_cases") OVER (PARTITION BY "state_name", "county" ORDER BY "date"), 0)'

# Also try LEAD style: next day - today as "increase toward next day" - unlikely
# Or cases themselves instead of new cases

TARGETS = {
    "a_s": [("New York", 90), ("California", 69), ("New Jersey", 65), ("Illinois", 54), ("Massachusetts", 50)],
    "a_c": [("Cook", 87), ("Lake", 77), ("DuPage", 75), ("Kane", 67), ("Will", 63)],
    "c_s": [("New York", 89), ("California", 70), ("New Jersey", 63), ("Illinois", 55), ("Massachusetts", 50)],
    "c_c": [("Cook", 92), ("Lake", 79), ("DuPage", 76), ("Kane", 70), ("Will", 62)],
    "d_s": [("New York", 89), ("California", 69), ("New Jersey", 65), ("Illinois", 54), ("Massachusetts", 50)],
    "d_c": [("Cook", 87), ("Lake", 77), ("DuPage", 75), ("Kane", 67), ("Will", 62)],
    "e_s": [("New York", 90), ("California", 70), ("New Jersey", 64), ("Illinois", 54), ("Massachusetts", 50)],
    "e_c": [("Cook", 91), ("Lake", 78), ("DuPage", 76), ("Kane", 69), ("Will", 62)],
}


def to_pairs(df, key):
    return [(r[key], int(r["freq"])) for _, r in df.iterrows()]


def main():
    conn = connect()
    cur = conn.cursor()

    variants = [
        ("s_lag_nn_name", S_LAG, "new_cases DESC, \"state_name\"", "AND new_cases IS NOT NULL"),
        ("s_lag_nn_fname", S_LAG, "new_cases DESC, \"state_name\" DESC", "AND new_cases IS NOT NULL"),
        ("s_lag_ge0_name", S_LAG, "new_cases DESC, \"state_name\"", "AND new_cases IS NOT NULL AND new_cases >= 0"),
        ("s_lag_gt0_name", S_LAG, "new_cases DESC, \"state_name\"", "AND new_cases IS NOT NULL AND new_cases > 0"),
        ("s_coal_nn_name", S_COAL, "new_cases DESC, \"state_name\"", ""),
        ("s_coal_ge0_name", S_COAL, "new_cases DESC, \"state_name\"", "AND new_cases >= 0"),
        ("s_coal_gt0_name", S_COAL, "new_cases DESC, \"state_name\"", "AND new_cases > 0"),
        ("s_lag_ge0_only", S_LAG, "new_cases DESC", "AND new_cases IS NOT NULL AND new_cases >= 0"),
        ("s_abs_lag", f"ABS({S_LAG})", "new_cases DESC, \"state_name\"", "AND new_cases IS NOT NULL"),
        ("s_cases_raw", '"confirmed_cases"', "new_cases DESC, \"state_name\"", ""),
        ("s_lag_g0", f"GREATEST({S_LAG}, 0)", "new_cases DESC, \"state_name\"", "AND new_cases IS NOT NULL"),
        # date windows
        ("s_lag_ge0_mar1may30", S_LAG, "new_cases DESC, \"state_name\"", "AND new_cases IS NOT NULL AND new_cases >= 0", "2020-03-01", "2020-05-30"),
        ("s_lag_nn_mar1may30", S_LAG, "new_cases DESC, \"state_name\"", "AND new_cases IS NOT NULL", "2020-03-01", "2020-05-30"),
        ("s_lag_nn_feb29may31", S_LAG, "new_cases DESC, \"state_name\"", "AND new_cases IS NOT NULL", "2020-02-29", "2020-05-31"),
        ("s_lag_ge0_apr1may31", S_LAG, "new_cases DESC, \"state_name\"", "AND new_cases IS NOT NULL AND new_cases >= 0", "2020-04-01", "2020-05-31"),
    ]

    print("=== STATE VARIANTS ===")
    for v in variants:
        name, expr, ob, fc = v[0], v[1], v[2], v[3]
        ds = v[4] if len(v) > 4 else "2020-03-01"
        de = v[5] if len(v) > 5 else "2020-05-31"
        df = run(cur, state_sql(expr, ob, fc, ds, de))
        pairs = to_pairs(df, "state_name")
        hits = [t for t, exp in TARGETS.items() if t.endswith("_s") and pairs == exp]
        print(f"{name}: {pairs}" + (f" >>> {hits}" if hits else ""))

    cvariants = [
        ("c_lag_nn_name", C_LAG, "new_cases DESC, \"county\"", "AND new_cases IS NOT NULL"),
        ("c_lag_ge0_name", C_LAG, "new_cases DESC, \"county\"", "AND new_cases IS NOT NULL AND new_cases >= 0"),
        ("c_lag_gt0_name", C_LAG, "new_cases DESC, \"county\"", "AND new_cases IS NOT NULL AND new_cases > 0"),
        ("c_coal_nn_name", C_COAL, "new_cases DESC, \"county\"", ""),
        ("c_coal_ge0_name", C_COAL, "new_cases DESC, \"county\"", "AND new_cases >= 0"),
        ("c_coal_gt0_name", C_COAL, "new_cases DESC, \"county\"", "AND new_cases > 0"),
        ("c_lag_ge0_unk", C_LAG, "new_cases DESC, \"county\"", "AND new_cases IS NOT NULL AND new_cases >= 0 AND \"county\" <> 'Unknown'"),
        ("c_lag_nn_unk", C_LAG, "new_cases DESC, \"county\"", "AND new_cases IS NOT NULL AND \"county\" <> 'Unknown'"),
        ("c_lag_gt0_unk", C_LAG, "new_cases DESC, \"county\"", "AND new_cases IS NOT NULL AND new_cases > 0 AND \"county\" <> 'Unknown'"),
        ("c_coal_gt0_unk", C_COAL, "new_cases DESC, \"county\"", "AND new_cases > 0 AND \"county\" <> 'Unknown'"),
        ("c_lag_g0", f"GREATEST({C_LAG}, 0)", "new_cases DESC, \"county\"", "AND new_cases IS NOT NULL"),
        ("c_lag_ge0_may30", C_LAG, "new_cases DESC, \"county\"", "AND new_cases IS NOT NULL AND new_cases >= 0", "2020-03-01", "2020-05-30"),
        ("c_lag_nn_may30", C_LAG, "new_cases DESC, \"county\"", "AND new_cases IS NOT NULL", "2020-03-01", "2020-05-30"),
        ("c_lag_gt0_may30", C_LAG, "new_cases DESC, \"county\"", "AND new_cases IS NOT NULL AND new_cases > 0", "2020-03-01", "2020-05-30"),
        ("c_cases_raw", '"confirmed_cases"', "new_cases DESC, \"county\"", ""),
        ("c_lag_ge0_fname", C_LAG, "new_cases DESC, \"county\" DESC", "AND new_cases IS NOT NULL AND new_cases >= 0"),
        ("c_lag_nn_fips", C_LAG, "new_cases DESC, \"county\"", "AND new_cases IS NOT NULL"),  # same
    ]

    print("\n=== COUNTY VARIANTS ===")
    for v in cvariants:
        name, expr, ob, fc = v[0], v[1], v[2], v[3]
        ds = v[4] if len(v) > 4 else "2020-03-01"
        de = v[5] if len(v) > 5 else "2020-05-31"
        df = run(cur, county_sql(expr, ob, fc, ds, de))
        pairs = to_pairs(df, "county")
        hits = [t for t, exp in TARGETS.items() if t.endswith("_c") and pairs == exp]
        print(f"{name}: {pairs}" + (f" >>> {hits}" if hits else ""))

    # Check how many days in Mar-May
    print("\n=== day counts ===")
    print(run(cur, '''
      SELECT COUNT(DISTINCT "date") d
      FROM COVID19_NYT.COVID19_NYT.US_STATES
      WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31'
    '''))

    conn.close()


if __name__ == "__main__":
    main()
