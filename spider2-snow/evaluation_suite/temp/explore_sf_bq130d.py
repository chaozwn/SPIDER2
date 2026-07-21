#!/usr/bin/env python3
"""Find remaining a/b/d variants for sf_bq130."""
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
    return pd.DataFrame(cur.fetchall(), columns=[d[0].lower() for d in cur.description])


TARGETS_S = {
    "a": [("New York", 90), ("California", 69), ("New Jersey", 65), ("Illinois", 54), ("Massachusetts", 50)],
    "d": [("New York", 89), ("California", 69), ("New Jersey", 65), ("Illinois", 54), ("Massachusetts", 50)],
}
TARGETS_C = {
    "a": [("Cook", 87), ("Lake", 77), ("DuPage", 75), ("Kane", 67), ("Will", 63)],
}


def pairs(df, k):
    return [(r[k], int(r["freq"])) for _, r in df.iterrows()]


def main():
    conn = connect()
    cur = conn.cursor()

    # Try QUALIFY style, fips secondary, deaths secondary, etc.
    state_queries = {
        "lag_nn_fips": '''
WITH d AS (
  SELECT "date","state_name","state_fips_code",
    "confirmed_cases"-LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date") nc
  FROM COVID19_NYT.COVID19_NYT.US_STATES
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "state_fips_code") rn
  FROM d WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31' AND nc IS NOT NULL
)
SELECT "state_name", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
        "lag_nn_fips_desc": '''
WITH d AS (
  SELECT "date","state_name","state_fips_code",
    "confirmed_cases"-LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date") nc
  FROM COVID19_NYT.COVID19_NYT.US_STATES
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "state_fips_code" DESC) rn
  FROM d WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31' AND nc IS NOT NULL
)
SELECT "state_name", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
        "coal_nn_fips": '''
WITH d AS (
  SELECT "date","state_name","state_fips_code",
    "confirmed_cases"-COALESCE(LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date"),0) nc
  FROM COVID19_NYT.COVID19_NYT.US_STATES
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "state_fips_code") rn
  FROM d WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31'
)
SELECT "state_name", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
        "coal_nn_name_desc": '''
WITH d AS (
  SELECT "date","state_name",
    "confirmed_cases"-COALESCE(LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date"),0) nc
  FROM COVID19_NYT.COVID19_NYT.US_STATES
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "state_name" DESC) rn
  FROM d WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31'
)
SELECT "state_name", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
        "lag_gt0_name_desc": '''
WITH d AS (
  SELECT "date","state_name",
    "confirmed_cases"-LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date") nc
  FROM COVID19_NYT.COVID19_NYT.US_STATES
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "state_name" DESC) rn
  FROM d WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31' AND nc > 0
)
SELECT "state_name", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
        "lag_ge0_name_desc": '''
WITH d AS (
  SELECT "date","state_name",
    "confirmed_cases"-LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date") nc
  FROM COVID19_NYT.COVID19_NYT.US_STATES
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "state_name" DESC) rn
  FROM d WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31' AND nc >= 0
)
SELECT "state_name", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
        "coal_gt0_name_desc": '''
WITH d AS (
  SELECT "date","state_name",
    "confirmed_cases"-COALESCE(LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date"),0) nc
  FROM COVID19_NYT.COVID19_NYT.US_STATES
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "state_name" DESC) rn
  FROM d WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31' AND nc > 0
)
SELECT "state_name", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
        # filter months via EXTRACT
        "lag_nn_extract": '''
WITH d AS (
  SELECT "date","state_name",
    "confirmed_cases"-LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date") nc
  FROM COVID19_NYT.COVID19_NYT.US_STATES
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "state_name") rn
  FROM d WHERE YEAR("date")=2020 AND MONTH("date") BETWEEN 3 AND 5 AND nc IS NOT NULL
)
SELECT "state_name", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
        # use deaths? unlikely
        # maybe new cases only when previous day exists AND date range for lag window restricted?
        "lag_within_window": '''
WITH base AS (
  SELECT * FROM COVID19_NYT.COVID19_NYT.US_STATES
  WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31'
),
d AS (
  SELECT "date","state_name",
    "confirmed_cases"-LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date") nc
  FROM base
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "state_name") rn
  FROM d WHERE nc IS NOT NULL
)
SELECT "state_name", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
        "coal_within_window": '''
WITH base AS (
  SELECT * FROM COVID19_NYT.COVID19_NYT.US_STATES
  WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31'
),
d AS (
  SELECT "date","state_name",
    "confirmed_cases"-COALESCE(LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date"),0) nc
  FROM base
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "state_name") rn
  FROM d
)
SELECT "state_name", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
        # include Feb 29 in window for lag then filter Mar-May
        "lag_from_feb": '''
WITH base AS (
  SELECT * FROM COVID19_NYT.COVID19_NYT.US_STATES
  WHERE "date" BETWEEN '2020-02-29' AND '2020-05-31'
),
d AS (
  SELECT "date","state_name",
    "confirmed_cases"-LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date") nc
  FROM base
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "state_name") rn
  FROM d WHERE "date" >= '2020-03-01' AND nc IS NOT NULL
)
SELECT "state_name", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
        # TOP_K_PER_GROUP via QUALIFY
        "qualify_coal": '''
WITH d AS (
  SELECT "date","state_name",
    "confirmed_cases"-COALESCE(LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date"),0) nc
  FROM COVID19_NYT.COVID19_NYT.US_STATES
  QUALIFY "date" BETWEEN '2020-03-01' AND '2020-05-31'
)
SELECT "state_name", COUNT(*) freq FROM d
QUALIFY ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "state_name") <= 5
GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
    }

    print("=== STATES ===")
    for name, sql in state_queries.items():
        try:
            df = run(cur, sql)
            p = pairs(df, "state_name")
            hits = [t for t, exp in TARGETS_S.items() if p == exp]
            print(f"{name}: {p}" + (f" >>> {hits}" if hits else ""))
        except Exception as e:
            print(f"{name}: ERROR {e}")

    county_queries = {
        "lag_gt0_name_desc": '''
WITH d AS (
  SELECT "date","county",
    "confirmed_cases"-LAG("confirmed_cases") OVER (PARTITION BY "county" ORDER BY "date") nc
  FROM COVID19_NYT.COVID19_NYT.US_COUNTIES WHERE "state_name"='Illinois'
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "county" DESC) rn
  FROM d WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31' AND nc > 0
)
SELECT "county", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
        "lag_gt0_name": '''
WITH d AS (
  SELECT "date","county",
    "confirmed_cases"-LAG("confirmed_cases") OVER (PARTITION BY "county" ORDER BY "date") nc
  FROM COVID19_NYT.COVID19_NYT.US_COUNTIES WHERE "state_name"='Illinois'
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "county") rn
  FROM d WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31' AND nc > 0
)
SELECT "county", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
        "coal_gt0_name_desc": '''
WITH d AS (
  SELECT "date","county",
    "confirmed_cases"-COALESCE(LAG("confirmed_cases") OVER (PARTITION BY "county" ORDER BY "date"),0) nc
  FROM COVID19_NYT.COVID19_NYT.US_COUNTIES WHERE "state_name"='Illinois'
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "county" DESC) rn
  FROM d WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31' AND nc > 0
)
SELECT "county", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
        "lag_nn_within": '''
WITH base AS (
  SELECT * FROM COVID19_NYT.COVID19_NYT.US_COUNTIES
  WHERE "state_name"='Illinois' AND "date" BETWEEN '2020-03-01' AND '2020-05-31'
),
d AS (
  SELECT "date","county",
    "confirmed_cases"-LAG("confirmed_cases") OVER (PARTITION BY "county" ORDER BY "date") nc
  FROM base
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "county") rn
  FROM d WHERE nc IS NOT NULL
)
SELECT "county", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
        "coal_within": '''
WITH base AS (
  SELECT * FROM COVID19_NYT.COVID19_NYT.US_COUNTIES
  WHERE "state_name"='Illinois' AND "date" BETWEEN '2020-03-01' AND '2020-05-31'
),
d AS (
  SELECT "date","county",
    "confirmed_cases"-COALESCE(LAG("confirmed_cases") OVER (PARTITION BY "county" ORDER BY "date"),0) nc
  FROM base
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "county") rn
  FROM d
)
SELECT "county", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
        "lag_gt0_within": '''
WITH base AS (
  SELECT * FROM COVID19_NYT.COVID19_NYT.US_COUNTIES
  WHERE "state_name"='Illinois' AND "date" BETWEEN '2020-03-01' AND '2020-05-31'
),
d AS (
  SELECT "date","county",
    "confirmed_cases"-LAG("confirmed_cases") OVER (PARTITION BY "county" ORDER BY "date") nc
  FROM base
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "county") rn
  FROM d WHERE nc > 0
)
SELECT "county", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
        "lag_gt0_fips": '''
WITH d AS (
  SELECT "date","county","county_fips_code",
    "confirmed_cases"-LAG("confirmed_cases") OVER (PARTITION BY "county" ORDER BY "date") nc
  FROM COVID19_NYT.COVID19_NYT.US_COUNTIES WHERE "state_name"='Illinois'
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "county_fips_code") rn
  FROM d WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31' AND nc > 0
)
SELECT "county", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
        "coal_nn_fips": '''
WITH d AS (
  SELECT "date","county","county_fips_code",
    "confirmed_cases"-COALESCE(LAG("confirmed_cases") OVER (PARTITION BY "county" ORDER BY "date"),0) nc
  FROM COVID19_NYT.COVID19_NYT.US_COUNTIES WHERE "state_name"='Illinois'
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "county_fips_code") rn
  FROM d WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31'
)
SELECT "county", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
        # maybe exclude New York City special / Unknown AND gt0 with name
        "lag_gt0_no_unk_name_desc": '''
WITH d AS (
  SELECT "date","county",
    "confirmed_cases"-LAG("confirmed_cases") OVER (PARTITION BY "county" ORDER BY "date") nc
  FROM COVID19_NYT.COVID19_NYT.US_COUNTIES
  WHERE "state_name"='Illinois' AND "county" <> 'Unknown'
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "county" DESC) rn
  FROM d WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31' AND nc > 0
)
SELECT "county", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1 LIMIT 5
''',
    }

    print("\n=== COUNTIES ===")
    for name, sql in county_queries.items():
        try:
            df = run(cur, sql)
            p = pairs(df, "county")
            hits = [t for t, exp in TARGETS_C.items() if p == exp]
            print(f"{name}: {p}" + (f" >>> {hits}" if hits else ""))
        except Exception as e:
            print(f"{name}: ERROR {e}")

    # Full ranking for d (more than top5) with various methods
    print("\n=== FULL STATE RANK coal_name (for d/e) ===")
    print(run(cur, '''
WITH d AS (
  SELECT "date","state_name",
    "confirmed_cases"-COALESCE(LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date"),0) nc
  FROM COVID19_NYT.COVID19_NYT.US_STATES
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "state_name") rn
  FROM d WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31'
)
SELECT "state_name", COUNT(*) freq,
  ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC, "state_name") rank
FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1
'''))

    print("\n=== FULL STATE RANK lag_nn_name (for c/d) ===")
    print(run(cur, '''
WITH d AS (
  SELECT "date","state_name",
    "confirmed_cases"-LAG("confirmed_cases") OVER (PARTITION BY "state_name" ORDER BY "date") nc
  FROM COVID19_NYT.COVID19_NYT.US_STATES
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY "date" ORDER BY nc DESC, "state_name") rn
  FROM d WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31' AND nc IS NOT NULL
)
SELECT "state_name", COUNT(*) freq FROM r WHERE rn<=5 GROUP BY 1 ORDER BY 2 DESC,1
'''))

    conn.close()


if __name__ == "__main__":
    main()
