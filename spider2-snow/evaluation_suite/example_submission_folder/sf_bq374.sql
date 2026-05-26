/*
================================================================================
  sf_bq374.sql
  ────────────────────────────────────────────────────────────────────────────
  Business Question:
    "Calculates the percentage of new users who, between August 1, 2016,
     and April 30, 2017, both stayed on the site for more than 5 minutes
     during their initial visit AND made a purchase on a subsequent visit
     at any later time, relative to the total number of new users in the
     same period."

  Deliverable:
    Single-row, three-column result set:
      total_new_users  |  qualifying_users  |  pct
    -------------------------------------------------
            549,137    |       1,602        |  0.2917

  Assumptions:
    1. A "new user" is identified by `totals:"newVisits" = 1` in their
       first session within the date range.
    2. "Stayed on the site for more than 5 minutes" means
       `totals:"timeOnSite" > 300` (seconds).
    3. "Made a purchase on a subsequent visit" means the same
       `fullVisitorId` has at least one session with
       `CAST(totals:"transactions" AS INTEGER) >= 1` where
       `visitNumber > 1`, in **any** available table (through Aug 2017).
    4. Table names follow the convention `GA_SESSIONS_YYYYMMDD` for each
       calendar day. All daily tables in the query's date range must exist
       in the target Snowflake account.

  Execution:
    Run the entire script in Snowflake. The final SELECT is the only
    non-CTE statement and produces the desired result.
================================================================================
*/

WITH

-- ==========================================================================
-- Step 1: Gather all first (new) visits between Aug 1, 2016 and Apr 30, 2017
-- ==========================================================================
first_visits AS (
  SELECT "fullVisitorId",
         CAST("totals":"timeOnSite" AS INTEGER) AS "time_on_site"
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160801"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160802"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160803"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160804"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160805"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160806"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160807"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160808"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160809"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160810"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160811"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160812"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160813"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160814"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160815"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160816"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160817"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160818"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160819"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160820"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160821"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160822"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160823"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160824"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160825"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160826"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160827"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160828"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160829"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160830"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160831"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160901"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160902"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160903"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160904"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160905"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160906"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160907"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160908"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160909"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160910"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160911"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160912"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160913"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160914"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160915"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160916"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160917"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160918"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160919"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160920"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160921"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160922"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160923"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160924"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160925"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160926"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160927"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160928"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160929"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160930"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161001"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161002"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161003"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161004"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161005"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161006"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161007"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161008"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161009"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161010"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161011"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161012"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161013"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161014"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161015"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161016"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161017"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161018"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161019"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161020"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161021"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161022"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161023"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161024"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161025"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161026"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161027"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161028"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161029"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161030"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161031"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161101"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161102"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161103"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161104"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161105"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161106"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161107"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161108"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161109"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161110"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161111"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161112"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161113"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161114"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161115"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161116"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161117"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161118"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161119"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161120"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161121"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161122"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161123"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161124"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161125"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161126"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161127"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161128"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161129"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161130"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161201"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161202"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161203"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161204"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161205"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161206"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161207"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161208"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161209"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161210"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161211"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161212"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161213"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161214"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161215"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161216"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161217"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161218"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161219"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161220"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161221"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161222"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161223"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161224"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161225"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161226"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161227"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161228"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161229"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161230"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161231"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170101"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170102"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170103"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170104"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170105"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170106"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170107"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170108"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170109"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170110"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170111"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170112"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170113"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170114"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170115"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170116"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170117"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170118"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170119"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170120"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170121"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170122"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170123"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170124"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170125"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170126"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170127"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170128"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170129"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170130"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170131"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170201"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170202"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170203"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170204"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170205"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170206"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170207"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170208"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170209"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170210"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170211"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170212"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170213"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170214"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170215"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170216"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170217"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170218"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170219"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170220"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170221"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170222"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170223"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170224"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170225"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170226"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170227"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170228"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170301"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170302"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170303"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170304"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170305"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170306"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170307"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170308"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170309"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170310"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170311"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170312"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170313"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170314"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170315"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170316"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170317"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170318"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170319"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170320"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170321"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170322"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170323"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170324"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170325"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170326"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170327"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170328"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170329"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170330"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170331"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170401"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170402"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170403"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170404"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170405"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170406"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170407"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170408"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170409"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170410"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170411"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170412"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170413"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170414"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170415"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170416"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170417"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170418"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170419"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170420"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170421"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170422"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170423"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170424"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170425"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170426"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170427"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170428"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170429"
  WHERE "totals":"newVisits" = 1
  UNION ALL
  SELECT "fullVisitorId", CAST("totals":"timeOnSite" AS INTEGER)
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170430"
  WHERE "totals":"newVisits" = 1
),

-- ==========================================================================
-- Step 2: Identify new users who stayed longer than 5 minutes (300 seconds)
-- ==========================================================================
stayed_long AS (
  SELECT DISTINCT "fullVisitorId"
  FROM first_visits
  WHERE COALESCE("time_on_site", 0) > 300
),

-- ==========================================================================
-- Step 3: Gather all purchase sessions (visitNumber > 1 = subsequent visit)
--          across ALL available daily tables (through Aug 2017)
-- ==========================================================================
all_purchases AS (
  SELECT "fullVisitorId"
  FROM (
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160801"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160802"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160803"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160804"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160805"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160806"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160807"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160808"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160809"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160810"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160811"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160812"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160813"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160814"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160815"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160816"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160817"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160818"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160819"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160820"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160821"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160822"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160823"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160824"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160825"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160826"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160827"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160828"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160829"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160830"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160831"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160901"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160902"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160903"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160904"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160905"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160906"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160907"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160908"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160909"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160910"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160911"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160912"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160913"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160914"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160915"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160916"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160917"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160918"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160919"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160920"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160921"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160922"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160923"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160924"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160925"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160926"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160927"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160928"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160929"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20160930"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161001"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161002"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161003"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161004"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161005"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161006"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161007"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161008"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161009"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161010"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161011"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161012"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161013"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161014"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161015"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161016"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161017"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161018"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161019"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161020"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161021"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161022"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161023"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161024"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161025"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161026"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161027"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161028"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161029"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161030"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161031"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161101"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161102"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161103"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161104"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161105"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161106"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161107"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161108"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161109"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161110"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161111"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161112"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161113"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161114"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161115"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161116"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161117"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161118"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161119"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161120"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161121"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161122"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161123"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161124"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161125"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161126"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161127"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161128"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161129"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161130"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161201"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161202"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161203"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161204"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161205"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161206"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161207"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161208"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161209"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161210"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161211"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161212"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161213"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161214"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161215"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161216"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161217"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161218"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161219"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161220"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161221"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161222"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161223"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161224"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161225"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161226"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161227"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161228"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161229"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161230"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20161231"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170101"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170102"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170103"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170104"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170105"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170106"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170107"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170108"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170109"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170110"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170111"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170112"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170113"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170114"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170115"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170116"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170117"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170118"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170119"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170120"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170121"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170122"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170123"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170124"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170125"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170126"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170127"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170128"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170129"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170130"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170131"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170201"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170202"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170203"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170204"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170205"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170206"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170207"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170208"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170209"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170210"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170211"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170212"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170213"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170214"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170215"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170216"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170217"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170218"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170219"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170220"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170221"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170222"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170223"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170224"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170225"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170226"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170227"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170228"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170301"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170302"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170303"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170304"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170305"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170306"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170307"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170308"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170309"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170310"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170311"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170312"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170313"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170314"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170315"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170316"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170317"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170318"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170319"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170320"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170321"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170322"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170323"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170324"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170325"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170326"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170327"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170328"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170329"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170330"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170331"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170401"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170402"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170403"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170404"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170405"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170406"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170407"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170408"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170409"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170410"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170411"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170412"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170413"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170414"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170415"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170416"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170417"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170418"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170419"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170420"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170421"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170422"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170423"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170424"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170425"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170426"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170427"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170428"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170429"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170430"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170501"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170601"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170701"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
    UNION ALL
    SELECT "fullVisitorId", "visitNumber"
    FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170801"
    WHERE CAST("totals":"transactions" AS INTEGER) >= 1
  )
  WHERE "visitNumber" > 1
)

-- ==========================================================================
-- Final Answer: One row, three columns
-- ==========================================================================
SELECT
  COUNT(DISTINCT fv."fullVisitorId")    AS "total_new_users",
  COUNT(DISTINCT
    CASE
      WHEN sl."fullVisitorId" IS NOT NULL
       AND ap."fullVisitorId" IS NOT NULL
      THEN fv."fullVisitorId"
    END
  )                                      AS "qualifying_users",
  ROUND(
    COUNT(DISTINCT
      CASE
        WHEN sl."fullVisitorId" IS NOT NULL
         AND ap."fullVisitorId" IS NOT NULL
        THEN fv."fullVisitorId"
      END
    ) * 100.0 /
    NULLIF(COUNT(DISTINCT fv."fullVisitorId"), 0),
    4
  )                                      AS "pct"
FROM first_visits fv
LEFT JOIN stayed_long sl
  ON fv."fullVisitorId" = sl."fullVisitorId"
LEFT JOIN all_purchases ap
  ON fv."fullVisitorId" = ap."fullVisitorId";