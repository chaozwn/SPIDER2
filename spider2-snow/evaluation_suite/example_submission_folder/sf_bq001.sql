/*
 * sf_bq001.sql
 *
 * Business Question:
 *   For each visitor who made at least one transaction in February 2017,
 *   how many days elapsed between the date of their first visit in February
 *   and the date of their first transaction in February, and on what type
 *   of device did they make that first transaction?
 *
 * Output columns:
 *   fullVisitorId    — The unique visitor ID (string)
 *   days_elapsed     — Number of days between first visit and first transaction
 *                      in February 2017 (integer)
 *   device_category  — Device category on which the first transaction was made
 *                      ("desktop", "mobile", or "tablet")
 *
 * Assumptions:
 *   1. A "visit" is any session row in a GA_SESSIONS_* daily table for Feb 2017.
 *   2. A "transaction" is identified by totals.transactions > 0 as an integer.
 *   3. The first visit date is the earliest session date in Feb 2017 for that
 *      visitor, regardless of whether it was a transaction session or not.
 *   4. The first transaction date is the earliest session date in Feb 2017
 *      where totals.transactions > 0.
 *   5. The device category for the first transaction is taken from the same
 *      session (row) where that first transaction occurred.
 *   6. If the first visit and the first transaction occur on the same date,
 *      days_elapsed = 0.
 *
 * Note on table names:
 *   The GA_SESSIONS_YYYYMMDD tables are daily export tables. The sample data
 *   set used here stores them without an explicit schema prefix. Adjust the
 *   database.schema qualifier below to match your Snowflake environment
 *   (e.g. GOOGLE_ANALYTICS_SAMPLE.PUBLIC.GA_SESSIONS_*).
 */

-- Step 1: Union all 28 daily tables for February 2017 into one dataset
WITH feb_all_sessions AS (
  SELECT "fullVisitorId",
         "date",
         "device":"deviceCategory"::VARCHAR AS "device_category",
         "totals":"transactions"::INTEGER AS "transactions"
  FROM "GA_SESSIONS_20170201"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170202"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170203"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170204"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170205"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170206"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170207"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170208"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170209"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170210"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170211"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170212"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170213"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170214"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170215"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170216"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170217"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170218"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170219"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170220"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170221"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170222"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170223"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170224"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170225"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170226"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170227"
  UNION ALL
  SELECT "fullVisitorId", "date", "device":"deviceCategory"::VARCHAR, "totals":"transactions"::INTEGER
  FROM "GA_SESSIONS_20170228"
),

-- Step 2: For each visitor, find first visit date, first transaction date,
--         and the device category of that first transaction
visitor_dates AS (
  SELECT "fullVisitorId",
         MIN("date") AS "first_visit_date",
         MIN(CASE WHEN "transactions" > 0 THEN "date" END) AS "first_txn_date",
         MIN(CASE WHEN "transactions" > 0 THEN "device_category" END) AS "first_txn_device_category"
  FROM feb_all_sessions
  GROUP BY "fullVisitorId"
  -- Keep only visitors who had at least one transaction in Feb 2017
  HAVING MIN(CASE WHEN "transactions" > 0 THEN "date" END) IS NOT NULL
)

-- Step 3: Final SELECT — compute days elapsed and present the answer
SELECT "fullVisitorId",
       DATEDIFF('day',
                TO_DATE("first_visit_date", 'YYYYMMDD'),
                TO_DATE("first_txn_date", 'YYYYMMDD')) AS "days_elapsed",
       "first_txn_device_category" AS "device_category"
FROM visitor_dates
ORDER BY "fullVisitorId";