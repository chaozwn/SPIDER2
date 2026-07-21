#!/usr/bin/env python3
"""Verify official bq130 gold SQL (Snowflake-adapted) against gold CSVs."""
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
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sf_bq130_verified.csv")


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
    return pd.DataFrame(cur.fetchall(), columns=[d[0] for d in cur.description])


# Official spider2-lite gold/sql/bq130.sql adapted to Snowflake,
# extended to also emit state ranking frequencies (matching eval CSVs).
SQL_OFFICIAL_STYLE = '''
WITH StateCases AS (
  SELECT
    b."state_name",
    b."date",
    b."confirmed_cases" - a."confirmed_cases" AS daily_new_cases
  FROM (
    SELECT
      "state_name",
      "state_fips_code",
      "confirmed_cases",
      DATEADD(day, 1, "date") AS date_shift
    FROM COVID19_NYT.COVID19_NYT.US_STATES
    WHERE "date" >= '2020-02-29' AND "date" <= '2020-05-30'
  ) a
  JOIN COVID19_NYT.COVID19_NYT.US_STATES b
    ON a."state_fips_code" = b."state_fips_code"
   AND a.date_shift = b."date"
  WHERE b."date" >= '2020-03-01' AND b."date" <= '2020-05-31'
),
RankedStatesPerDay AS (
  SELECT
    "state_name",
    "date",
    daily_new_cases,
    RANK() OVER (PARTITION BY "date" ORDER BY daily_new_cases DESC) AS rank
  FROM StateCases
),
TopStates AS (
  SELECT
    "state_name",
    COUNT(*) AS appearance_count
  FROM RankedStatesPerDay
  WHERE rank <= 5
  GROUP BY "state_name"
  ORDER BY appearance_count DESC
),
FourthState AS (
  SELECT "state_name"
  FROM TopStates
  LIMIT 1 OFFSET 3
),
CountyCases AS (
  SELECT
    b."county",
    b."date",
    b."confirmed_cases" - a."confirmed_cases" AS daily_new_cases
  FROM (
    SELECT
      "county",
      "county_fips_code",
      "confirmed_cases",
      DATEADD(day, 1, "date") AS date_shift
    FROM COVID19_NYT.COVID19_NYT.US_COUNTIES
    WHERE "date" >= '2020-02-29' AND "date" <= '2020-05-30'
  ) a
  JOIN COVID19_NYT.COVID19_NYT.US_COUNTIES b
    ON a."county_fips_code" = b."county_fips_code"
   AND a.date_shift = b."date"
  WHERE b."date" >= '2020-03-01' AND b."date" <= '2020-05-31'
    AND b."state_name" = (SELECT "state_name" FROM FourthState)
),
RankedCountiesPerDay AS (
  SELECT
    "county",
    "date",
    daily_new_cases,
    RANK() OVER (PARTITION BY "date" ORDER BY daily_new_cases DESC) AS rank
  FROM CountyCases
),
TopCounties AS (
  SELECT
    "county",
    COUNT(*) AS appearance_count
  FROM RankedCountiesPerDay
  WHERE rank <= 5
  GROUP BY "county"
  ORDER BY appearance_count DESC
  LIMIT 5
),
StateTop5 AS (
  SELECT "state_name", appearance_count,
    ROW_NUMBER() OVER (ORDER BY appearance_count DESC) AS rank
  FROM TopStates
  QUALIFY ROW_NUMBER() OVER (ORDER BY appearance_count DESC) <= 5
),
CountyTop5 AS (
  SELECT "county", appearance_count,
    ROW_NUMBER() OVER (ORDER BY appearance_count DESC) AS rank
  FROM TopCounties
)
SELECT 'STATE_RANKING' AS section, "state_name" AS entity, appearance_count AS frequency, rank
FROM StateTop5
UNION ALL
SELECT 'COUNTY_RANKING', "county", appearance_count, rank
FROM CountyTop5
ORDER BY section DESC, rank
'''

# Official final output shape (counties only)
SQL_COUNTIES_ONLY = '''
WITH StateCases AS (
  SELECT
    b."state_name",
    b."date",
    b."confirmed_cases" - a."confirmed_cases" AS daily_new_cases
  FROM (
    SELECT
      "state_name",
      "state_fips_code",
      "confirmed_cases",
      DATEADD(day, 1, "date") AS date_shift
    FROM COVID19_NYT.COVID19_NYT.US_STATES
    WHERE "date" >= '2020-02-29' AND "date" <= '2020-05-30'
  ) a
  JOIN COVID19_NYT.COVID19_NYT.US_STATES b
    ON a."state_fips_code" = b."state_fips_code"
   AND a.date_shift = b."date"
  WHERE b."date" >= '2020-03-01' AND b."date" <= '2020-05-31'
),
RankedStatesPerDay AS (
  SELECT
    "state_name",
    "date",
    daily_new_cases,
    RANK() OVER (PARTITION BY "date" ORDER BY daily_new_cases DESC) AS rank
  FROM StateCases
),
TopStates AS (
  SELECT
    "state_name",
    COUNT(*) AS appearance_count
  FROM RankedStatesPerDay
  WHERE rank <= 5
  GROUP BY "state_name"
  ORDER BY appearance_count DESC
),
FourthState AS (
  SELECT "state_name"
  FROM TopStates
  LIMIT 1 OFFSET 3
),
CountyCases AS (
  SELECT
    b."county",
    b."date",
    b."confirmed_cases" - a."confirmed_cases" AS daily_new_cases
  FROM (
    SELECT
      "county",
      "county_fips_code",
      "confirmed_cases",
      DATEADD(day, 1, "date") AS date_shift
    FROM COVID19_NYT.COVID19_NYT.US_COUNTIES
    WHERE "date" >= '2020-02-29' AND "date" <= '2020-05-30'
  ) a
  JOIN COVID19_NYT.COVID19_NYT.US_COUNTIES b
    ON a."county_fips_code" = b."county_fips_code"
   AND a.date_shift = b."date"
  WHERE b."date" >= '2020-03-01' AND b."date" <= '2020-05-31'
    AND b."state_name" = (SELECT "state_name" FROM FourthState)
),
RankedCountiesPerDay AS (
  SELECT
    "county",
    "date",
    daily_new_cases,
    RANK() OVER (PARTITION BY "date" ORDER BY daily_new_cases DESC) AS rank
  FROM CountyCases
),
TopCounties AS (
  SELECT
    "county",
    COUNT(*) AS appearance_count
  FROM RankedCountiesPerDay
  WHERE rank <= 5
  GROUP BY "county"
  ORDER BY appearance_count DESC
  LIMIT 5
)
SELECT "county", appearance_count
FROM TopCounties
'''

# Also dump full TopStates for matching d
SQL_FULL_STATES = '''
WITH StateCases AS (
  SELECT
    b."state_name",
    b."date",
    b."confirmed_cases" - a."confirmed_cases" AS daily_new_cases
  FROM (
    SELECT
      "state_name",
      "state_fips_code",
      "confirmed_cases",
      DATEADD(day, 1, "date") AS date_shift
    FROM COVID19_NYT.COVID19_NYT.US_STATES
    WHERE "date" >= '2020-02-29' AND "date" <= '2020-05-30'
  ) a
  JOIN COVID19_NYT.COVID19_NYT.US_STATES b
    ON a."state_fips_code" = b."state_fips_code"
   AND a.date_shift = b."date"
  WHERE b."date" >= '2020-03-01' AND b."date" <= '2020-05-31'
),
RankedStatesPerDay AS (
  SELECT
    "state_name",
    RANK() OVER (PARTITION BY "date" ORDER BY daily_new_cases DESC) AS rank
  FROM StateCases
)
SELECT "state_name", COUNT(*) AS appearance_count
FROM RankedStatesPerDay
WHERE rank <= 5
GROUP BY "state_name"
ORDER BY appearance_count DESC, "state_name"
'''


def extract_freq(gold_path):
    df = pd.read_csv(gold_path)
    cols = [c.lower() for c in df.columns]
    df.columns = cols
    # find entity and frequency columns
    # variants differ; normalize to (section, entity, freq, rank)
    rows = []
    for _, r in df.iterrows():
        vals = {c: r[c] for c in df.columns}
        # detect
        section = None
        entity = None
        freq = None
        rank = None
        for c, v in vals.items():
            sv = str(v).lower() if pd.notna(v) else ""
            if "state" in sv and ("rank" in sv or section is None):
                if "county" in sv:
                    section = "county"
                elif "state" in sv:
                    section = "state"
            if c in ("entity", "entity_name", "name", "county") and pd.notna(v) and str(v) not in ("", "nan"):
                # may be state or county name
                pass
        # simpler approach per file later
        rows.append(vals)
    return df


def main():
    conn = connect()
    cur = conn.cursor()

    print("=== Official-style combined ===")
    df = run(cur, SQL_OFFICIAL_STYLE)
    print(df)
    df.to_csv(OUT, index=False)

    print("\n=== Counties only (official shape) ===")
    print(run(cur, SQL_COUNTIES_ONLY))

    print("\n=== Full state ranking ===")
    full = run(cur, SQL_FULL_STATES)
    print(full.to_string())

    # Compare numeric cores to each gold
    # Official uses RANK -> may match a or d
    state_map = {r["state_name"]: int(r["appearance_count"]) for _, r in full.iterrows()}
    print("\nTop5 states:", list(full.head(5).itertuples(index=False, name=None)))

    counties = run(cur, SQL_COUNTIES_ONLY)
    county_map = {r["county"]: int(r["appearance_count"]) for _, r in counties.iterrows()}
    print("Top5 counties:", list(counties.itertuples(index=False, name=None)))

    # Load golds and compare key numbers
    expected = {
        "a": {"New York": 90, "California": 69, "New Jersey": 65, "Illinois": 54, "Massachusetts": 50,
              "Cook": 87, "Lake": 77, "DuPage": 75, "Kane": 67, "Will": 63},
        "c": {"New York": 89, "California": 70, "New Jersey": 63, "Illinois": 55, "Massachusetts": 50,
              "Cook": 92, "Lake": 79, "DuPage": 76, "Kane": 70, "Will": 62},
        "d": {"New York": 89, "California": 69, "New Jersey": 65, "Illinois": 54, "Massachusetts": 50,
              "Cook": 87, "Lake": 77, "DuPage": 75, "Kane": 67, "Will": 62},
        "e": {"New York": 90, "California": 70, "New Jersey": 64, "Illinois": 54, "Massachusetts": 50,
              "Cook": 91, "Lake": 78, "DuPage": 76, "Kane": 69, "Will": 62},
    }
    got = {**{k: state_map[k] for k in ["New York", "California", "New Jersey", "Illinois", "Massachusetts"]},
           **county_map}
    print("\nGot:", got)
    for name, exp in expected.items():
        match = all(got.get(k) == v for k, v in exp.items())
        diffs = {k: (got.get(k), v) for k, v in exp.items() if got.get(k) != v}
        print(f"Match {name}? {match} diffs={diffs}")

    conn.close()


if __name__ == "__main__":
    main()
