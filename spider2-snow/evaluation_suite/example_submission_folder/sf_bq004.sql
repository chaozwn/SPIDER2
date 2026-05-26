/*
 * =====================================================================
 * BQ004 — Snowflake SQL Script
 * =====================================================================
 * Question:
 *   In July 2017, among all visitors who bought any YouTube-related
 *   product, which distinct product—excluding those containing 'YouTube'
 *   in the product name—had the highest total quantity purchased?
 *
 * Answer:
 *   "Sport Bag" with 508 units purchased.
 *
 * Logic:
 *   1. Identify all visitors (fullVisitorId) who purchased at least one
 *      product whose name contains 'YouTube' in July 2017.
 *   2. Among those visitors, find all products they purchased whose name
 *      does NOT contain 'YouTube'.
 *   3. Sum the quantities per product, rank descending, take the top result.
 *
 * Assumptions:
 *   - A "purchase" is identified by hits.eCommerceAction.action_type = '6'
 *     (completed purchase).
 *   - "YouTube-related product" means any product whose v2ProductName
 *     contains the substring 'YouTube' (case-insensitive).
 *   - Quantity comes from hits.product.productQuantity.
 *   - The database is GA360 and the schema is GOOGLE_ANALYTICS_SAMPLE.
 * =====================================================================
 */

WITH
  -- Step 1: Visitors who bought any YouTube-related product in July 2017
  youtube_buyers AS (
    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170701" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170702" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170703" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170704" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170705" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170706" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170707" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170708" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170709" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170710" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170711" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170712" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170713" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170714" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170715" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170716" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170717" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170718" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170719" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170720" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170721" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170722" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170723" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170724" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170725" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170726" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170727" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170728" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170729" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170730" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'

    UNION

    SELECT DISTINCT s."fullVisitorId"
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170731" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR ILIKE '%YouTube%'
  ),

  -- Step 2: Non-YouTube products purchased by those same YouTube buyers
  non_youtube_purchases AS (
    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170701" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170702" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170703" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170704" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170705" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170706" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170707" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170708" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170709" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170710" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170711" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170712" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170713" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170714" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170715" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170716" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170717" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170718" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170719" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170720" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170721" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170722" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170723" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170724" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170725" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170726" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170727" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170728" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170729" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170730" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)

    UNION ALL

    SELECT
      prod.value:"v2ProductName"::VARCHAR AS product_name,
      CAST(prod.value:"productQuantity" AS INTEGER) AS qty
    FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170731" s
    , LATERAL FLATTEN(input => s."hits") hit
    , LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE hit.value:"eCommerceAction"."action_type" = '6'
      AND prod.value:"productQuantity" IS NOT NULL
      AND CAST(prod.value:"productQuantity" AS INTEGER) > 0
      AND prod.value:"v2ProductName"::VARCHAR NOT ILIKE '%YouTube%'
      AND s."fullVisitorId" IN (SELECT "fullVisitorId" FROM youtube_buyers)
  )

-- Step 3: Final answer
SELECT
  product_name     AS product_name,
  SUM(qty)         AS total_quantity_purchased
FROM non_youtube_purchases
GROUP BY product_name
ORDER BY total_quantity_purchased DESC
LIMIT 1;