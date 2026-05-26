/*
 * sf_bq010.sql
 * 
 * Question: Find the top-selling product among customers who bought
 * 'YouTube Men''s Vintage Henley' in July 2017, excluding itself.
 *
 * Assumptions:
 * 1. Data is stored in the GOOGLE_ANALYTICS_SAMPLE database with daily tables
 *    named GA_SESSIONS_YYYYMMDD (one per day).
 * 2. A purchase is identified by hits.eCommerceAction.action_type = 6
 *    ("Completed purchase" per the GA schema documentation).
 * 3. Product quantity defaults to 1 when productQuantity is NULL.
 * 4. "Top-selling" is measured by the highest total quantity sold.
 * 5. July 2017 means date range 20170701–20170731.
 * 6. The excluded product is 'YouTube Men''s Vintage Henley' (the exact product
 *    name string as stored in v2ProductName). Other similar products such as
 *    'Android Men''s Vintage Henley' or 'Google Vintage Henley Grey/Black'
 *    are NOT excluded since they are distinct products.
 *
 * Result: Google Sunglasses with sold_qty = 24.
 */

-- Step 1: Identify customers who bought 'YouTube Men''s Vintage Henley'
--         in any session during July 2017.
WITH henley_buyers AS (
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170701 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170702 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170703 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170704 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170705 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170706 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170707 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170708 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170709 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170710 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170711 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170712 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170713 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170714 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170715 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170716 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170717 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170718 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170719 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170720 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170721 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170722 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170723 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170724 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170725 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170726 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170727 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170728 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170729 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170730 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
    UNION
    SELECT DISTINCT s."fullVisitorId"
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170731 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
      AND p.value:"v2ProductName"::STRING = 'YouTube Men''s Vintage Henley'
),

-- Step 2: Get all purchases by those customers in July 2017, excluding
--         the target product, and aggregate to find the top seller.
all_purchases AS (
    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170701 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170702 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170703 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170704 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170705 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170706 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170707 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170708 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170709 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170710 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170711 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170712 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170713 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170714 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170715 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170716 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170717 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170718 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170719 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170720 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170721 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170722 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170723 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170724 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170725 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170726 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170727 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170728 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170729 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170730 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6

    UNION ALL

    SELECT s."fullVisitorId",
           p.value:"v2ProductName"::STRING AS product_name,
           COALESCE(p.value:"productQuantity"::INT, 1) AS quantity
    FROM GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170731 s,
         LATERAL FLATTEN(input => s."hits") h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE h.value:"eCommerceAction"."action_type"::INT = 6
)

-- Final answer: top-selling product excluding 'YouTube Men''s Vintage Henley'
SELECT product_name,
       SUM(quantity) AS sold_qty
FROM all_purchases
WHERE "fullVisitorId" IN (SELECT "fullVisitorId" FROM henley_buyers)
  AND product_name != 'YouTube Men''s Vintage Henley'
GROUP BY product_name
ORDER BY sold_qty DESC
LIMIT 1;