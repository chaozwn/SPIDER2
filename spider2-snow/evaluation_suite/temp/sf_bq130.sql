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
