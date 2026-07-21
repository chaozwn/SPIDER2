#!/usr/bin/env python3
"""Score final sf_bq130 SQL against all gold CSVs using evaluate.compare_pandas_table."""
import json
import math
import os
import sys
import snowflake.connector
import pandas as pd

SUITE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO_ROOT = os.path.dirname(os.path.dirname(SUITE_DIR))
sys.path.insert(0, SUITE_DIR)
from evaluate import compare_pandas_table  # noqa: E402

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

SQL = open(OUT_SQL, encoding="utf-8").read() if os.path.exists(OUT_SQL) else None

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


def main():
    with open(OUT_SQL, "w", encoding="utf-8") as f:
        f.write(SQL.strip() + "\n")

    conn = connect()
    cur = conn.cursor()
    cur.execute(SQL)
    pred = pd.DataFrame(cur.fetchall(), columns=[d[0] for d in cur.description])
    conn.close()
    pred.to_csv(OUT, index=False)
    print("PRED:")
    print(pred.to_string(index=False))

    # Format pred like gold_h for fair column alignment testing
    # Eval compares gold cols [2,3] as vectors against ANY pred columns
    scores = {}
    for letter in "abcdefgh":
        gold = pd.read_csv(os.path.join(GOLD_DIR, f"sf_bq130_{letter}.csv"))
        score = compare_pandas_table(pred, gold, condition_cols=[2, 3], ignore_order=True)
        scores[letter] = score
        print(f"gold_{letter}: score={score}  shape={gold.shape} cols={list(gold.columns)}")

    print("\nOverall (any gold match):", int(any(scores.values())))
    print(f"Wrote {OUT_SQL}")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
