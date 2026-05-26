/*
 * ============================================================================
 * sf_bq009.sql — Snowflake SQL Answer Script
 * ============================================================================
 * Business Question:
 *   Which traffic source has the highest total transaction revenue for the
 *   year 2017, and what is the difference in millions (rounded to two decimal
 *   places) between the highest and lowest monthly total transaction revenue
 *   for that traffic source?
 *
 * Logic:
 *   1. UNION ALL daily GA_SESSIONS_2017* tables (Jan 1 – Aug 1, 2017).
 *   2. Aggregate totalTransactionRevenue by trafficSource.source for 2017.
 *   3. Identify the source with the largest total — '(direct)'.
 *   4. For that source, aggregate revenue by month (year_month = SUBSTR(date,1,6)).
 *   5. Compute max(monthly) - min(monthly).
 *   6. Express the difference in millions of the base currency unit, rounded
 *      to 2 decimal places.
 *
 *   NOTE: Google Analytics stores totalTransactionRevenue in micros (value × 10^6).
 *         To convert micros → actual currency → millions of currency:
 *         micros / 10^6 / 10^6 = micros / 10^12.
 *
 * Output columns:
 *   traffic_source   — the traffic source with the highest 2017 revenue
 *   diff_in_millions — (highest_monthly - lowest_monthly) in millions,
 *                      rounded to 2 decimal places
 * ============================================================================
 */

WITH all_2017_revenue AS (
  SELECT
    "date",
    "trafficSource":"source"::varchar AS traffic_source,
    "totals":"totalTransactionRevenue"::integer AS txn_revenue_micros
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170101"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL
    AND "totals":"totalTransactionRevenue"::integer > 0

  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170102"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170103"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170104"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170105"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170106"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170107"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170108"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170109"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170110"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170111"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170112"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170113"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170114"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170115"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170116"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170117"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170118"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170119"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170120"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170121"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170122"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170123"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170124"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170125"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170126"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170127"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170128"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170129"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170130"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170131"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0

  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170201"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170202"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170203"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170204"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170205"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170206"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170207"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170208"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170209"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170210"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170211"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170212"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170213"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170214"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170215"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170216"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170217"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170218"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170219"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170220"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170221"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170222"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170223"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170224"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170225"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170226"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170227"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170228"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0

  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170301"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170302"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170303"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170304"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170305"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170306"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170307"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170308"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170309"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170310"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170311"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170312"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170313"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170314"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170315"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170316"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170317"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170318"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170319"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170320"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170321"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170322"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170323"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170324"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170325"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170326"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170327"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170328"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170329"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170330"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170331"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0

  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170401"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170402"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170403"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170404"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170405"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170406"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170407"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170408"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170409"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170410"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170411"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170412"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170413"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170414"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170415"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170416"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170417"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170418"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170419"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170420"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170421"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170422"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170423"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170424"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170425"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170426"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170427"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170428"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170429"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170430"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0

  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170501"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170502"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170503"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170504"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170505"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170506"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170507"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170508"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170509"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170510"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170511"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170512"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170513"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170514"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170515"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170516"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170517"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170518"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170519"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170520"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170521"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170522"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170523"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170524"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170525"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170526"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170527"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170528"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170529"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170530"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170531"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0

  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170601"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170602"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170603"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170604"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170605"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170606"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170607"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170608"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170609"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170610"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170611"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170612"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170613"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170614"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170615"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170616"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170617"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170618"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170619"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170620"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170621"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170622"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170623"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170624"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170625"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170626"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170627"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170628"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170629"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170630"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0

  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170701"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170702"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170703"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170704"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170705"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170706"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170707"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170708"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170709"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170710"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170711"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170712"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170713"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170714"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170715"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170716"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170717"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170718"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170719"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170720"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170721"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170722"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170723"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170724"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170725"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170726"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170727"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170728"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170729"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170730"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170731"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0

  UNION ALL
  SELECT "date","trafficSource":"source"::varchar,"totals":"totalTransactionRevenue"::integer
  FROM "GOOGLE_ANALYTICS_SAMPLE"."PUBLIC"."GA_SESSIONS_20170801"
  WHERE "totals":"totalTransactionRevenue" IS NOT NULL AND "totals":"totalTransactionRevenue"::integer > 0
),

-- Step 2: Total revenue by traffic source for 2017
source_totals AS (
  SELECT traffic_source,
         SUM(txn_revenue_micros) AS total_revenue_micros
  FROM all_2017_revenue
  GROUP BY traffic_source
  ORDER BY total_revenue_micros DESC
),

-- Step 3: Identify the top source
top_source AS (
  SELECT traffic_source
  FROM source_totals
  LIMIT 1
),

-- Step 4: Monthly revenue for the top source
monthly_revenue AS (
  SELECT SUBSTR("date", 1, 6) AS year_month,
         SUM(txn_revenue_micros) AS monthly_micros
  FROM all_2017_revenue
  WHERE traffic_source = (SELECT traffic_source FROM top_source)
  GROUP BY SUBSTR("date", 1, 6)
)

-- Step 5 & 6: Compute the final answer
SELECT
  (SELECT traffic_source FROM top_source) AS traffic_source,
  ROUND((MAX(monthly_micros) - MIN(monthly_micros)) / 1000000000000.0, 2) AS diff_in_millions
FROM monthly_revenue
ORDER BY traffic_source;