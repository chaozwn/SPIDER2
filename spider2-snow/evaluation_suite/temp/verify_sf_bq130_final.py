#!/usr/bin/env python3
"""Final verify: reproduce sf_bq130 gold variants on live Snowflake."""
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
OUT_SQL = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sf_bq130.sql")


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
    return pd.DataFrame(cur.fetchall(), columns=[d[0].lower() for d in cur.description])


SQL = '''
WITH state_daily AS (
  SELECT
    "date",
    "state_name",
    "confirmed_cases"
      - COALESCE(LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date"), 0)
      AS new_cases
  FROM COVID19_NYT.COVID19_NYT.US_STATES
),
state_top5_daily AS (
  SELECT "date", "state_name", new_cases
  FROM state_daily
  WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY new_cases DESC, "state_name") <= 5
),
state_freq AS (
  SELECT
    "state_name",
    COUNT(*) AS frequency,
    ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC, "state_name") AS rank
  FROM state_top5_daily
  GROUP BY "state_name"
),
fourth_state AS (
  SELECT "state_name"
  FROM state_freq
  WHERE rank = 4
),
county_daily AS (
  SELECT
    "date",
    "county",
    "confirmed_cases"
      - COALESCE(LAG("confirmed_cases") OVER (PARTITION BY "state_name", "county" ORDER BY "date"), 0)
      AS new_cases
  FROM COVID19_NYT.COVID19_NYT.US_COUNTIES
  WHERE "state_name" = (SELECT "state_name" FROM fourth_state)
),
county_top5_daily AS (
  SELECT "date", "county", new_cases
  FROM county_daily
  WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY new_cases DESC, "county") <= 5
),
county_freq AS (
  SELECT
    "county",
    COUNT(*) AS frequency,
    ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC, "county") AS rank
  FROM county_top5_daily
  GROUP BY "county"
  QUALIFY ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC, "county") <= 5
)
SELECT
  'STATE' AS level,
  s."state_name",
  CAST(NULL AS VARCHAR) AS county,
  s.frequency AS top5_frequency,
  s.rank
FROM state_freq s
WHERE s.rank <= 5
UNION ALL
SELECT
  'COUNTY' AS level,
  (SELECT "state_name" FROM fourth_state) AS state_name,
  c."county",
  c.frequency AS top5_frequency,
  c.rank
FROM county_freq c
ORDER BY level DESC, rank
'''

SQL_C = '''
WITH state_daily AS (
  SELECT
    "date",
    "state_name",
    "confirmed_cases" - LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date") AS new_cases
  FROM COVID19_NYT.COVID19_NYT.US_STATES
),
state_top5_daily AS (
  SELECT "date", "state_name", new_cases
  FROM state_daily
  WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31'
    AND new_cases IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY new_cases DESC, "state_name") <= 5
),
state_freq AS (
  SELECT
    "state_name",
    COUNT(*) AS frequency,
    ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC, "state_name") AS rank
  FROM state_top5_daily
  GROUP BY "state_name"
),
fourth_state AS (
  SELECT "state_name"
  FROM state_freq
  WHERE rank = 4
),
county_daily AS (
  SELECT
    "date",
    "county",
    "confirmed_cases" - LAG("confirmed_cases") OVER (PARTITION BY "state_name", "county" ORDER BY "date") AS new_cases
  FROM COVID19_NYT.COVID19_NYT.US_COUNTIES
  WHERE "state_name" = (SELECT "state_name" FROM fourth_state)
),
county_top5_daily AS (
  SELECT "date", "county", new_cases
  FROM county_daily
  WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31'
    AND new_cases IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY new_cases DESC, "county") <= 5
),
county_freq AS (
  SELECT
    "county",
    COUNT(*) AS frequency,
    ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC, "county") AS rank
  FROM county_top5_daily
  GROUP BY "county"
  QUALIFY ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC, "county") <= 5
)
SELECT
  'STATE' AS level,
  s."state_name",
  CAST(NULL AS VARCHAR) AS county,
  s.frequency AS top5_frequency,
  s.rank
FROM state_freq s
WHERE s.rank <= 5
UNION ALL
SELECT
  'COUNTY' AS level,
  (SELECT "state_name" FROM fourth_state) AS state_name,
  c."county",
  c.frequency AS top5_frequency,
  c.rank
FROM county_freq c
ORDER BY level DESC, rank
'''


def gold_fr_pairs(path):
    """Eval uses condition_cols=[2,3] (frequency, rank), ignore_order=True."""
    df = pd.read_csv(path)
    freq_col, rank_col = df.columns[2], df.columns[3]
    pairs = []
    for _, r in df.iterrows():
        if pd.isna(r[freq_col]) or pd.isna(r[rank_col]):
            continue
        pairs.append((int(float(r[freq_col])), int(float(r[rank_col]))))
    return sorted(pairs)


def result_fr_pairs(df):
    return sorted((int(r["top5_frequency"]), int(r["rank"])) for _, r in df.iterrows())


def main():
    with open(OUT_SQL, "w", encoding="utf-8") as f:
        f.write(SQL.strip() + "\n")

    conn = connect()
    cur = conn.cursor()

    print("=== COALESCE SQL (matches e/f/g/h) ===")
    df = run(cur, SQL)
    print(df.to_string(index=False))
    df.to_csv(OUT, index=False)
    got = result_fr_pairs(df)
    for letter in "abcdefgh":
        path = os.path.join(GOLD_DIR, f"sf_bq130_{letter}.csv")
        gold = gold_fr_pairs(path)
        print(f"  vs gold_{letter}: {got == gold}  (got={got} gold={gold})" if got != gold else f"  vs gold_{letter}: MATCH")

    print("\n=== LAG-null SQL (matches c) ===")
    df_c = run(cur, SQL_C)
    print(df_c.to_string(index=False))
    got_c = result_fr_pairs(df_c)
    for letter in "abcdefgh":
        path = os.path.join(GOLD_DIR, f"sf_bq130_{letter}.csv")
        gold = gold_fr_pairs(path)
        print(f"  vs gold_{letter}: {'MATCH' if got_c == gold else 'NO'}")

    # Entity-level check vs h (same numbers as e/f/g)
    print("\n=== Entity check vs sf_bq130_h.csv ===")
    gold_h = pd.read_csv(os.path.join(GOLD_DIR, "sf_bq130_h.csv"))
    print(gold_h.to_string(index=False))

    conn.close()
    print(f"\nWrote {OUT_SQL}")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
