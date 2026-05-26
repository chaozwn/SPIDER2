/*
 * Business Question:
 * What were the monthly add-to-cart and purchase conversion rates,
 * calculated as a percentage of pageviews on product details,
 * from January to March 2017?
 *
 * Assumptions:
 * - "Pageviews on product details" = hits with eCommerceAction.action_type = '2'
 *   (product detail views) where the product is NOT an impression
 *   (i.e. isImpression IS NULL OR isImpression = FALSE).
 * - "Add-to-cart" = hits with eCommerceAction.action_type = '3'.
 * - "Purchase" = hits with eCommerceAction.action_type = '6'.
 * - Duplicate hits within a session are deduplicated using a composite key
 *   of (hit index, fullVisitorId, visitId).
 * - Conversion rate = (target action count / product_detail_views) × 100,
 *   rounded to 2 decimal places.
 *
 * Output: One row per month (201701, 201702, 201703) with columns:
 *   month, add_to_cart_rate, purchase_rate
 */

WITH all_hits AS (
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170101" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170102" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170103" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170104" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170105" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170106" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170107" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170108" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170109" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170110" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170111" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170112" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170113" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170114" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170115" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170116" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170117" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170118" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170119" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170120" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170121" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170122" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170123" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170124" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170125" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170126" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170127" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170128" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170129" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170130" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170131" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170201" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170202" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170203" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170204" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170205" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170206" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170207" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170208" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170209" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170210" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170211" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170212" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170213" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170214" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170215" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170216" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170217" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170218" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170219" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170220" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170221" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170222" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170223" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170224" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170225" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170226" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170227" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170228" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170301" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170302" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170303" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170304" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170305" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170306" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170307" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170308" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170309" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170310" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170311" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170312" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170313" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170314" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170315" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170316" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170317" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170318" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170319" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170320" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170321" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170322" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170323" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170324" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170325" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170326" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170327" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170328" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170329" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170330" t,
         LATERAL FLATTEN(input => t."hits") h
    UNION ALL
    SELECT t."date", t."fullVisitorId", t."visitId", h."INDEX", h.value AS hit
    FROM "GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170331" t,
         LATERAL FLATTEN(input => t."hits") h
),
monthly_actions AS (
    SELECT
        SUBSTR(h."date", 1, 6) AS "month",
        COUNT(DISTINCT CASE
            WHEN h.hit:"eCommerceAction"."action_type" = '2'
                 AND (h.hit:"product"[0]."isImpression" IS NULL
                      OR h.hit:"product"[0]."isImpression"::BOOLEAN = FALSE)
            THEN h."INDEX" || '-' || h."fullVisitorId" || '-' || h."visitId"
        END) AS "product_detail_views",
        COUNT(DISTINCT CASE
            WHEN h.hit:"eCommerceAction"."action_type" = '3'
            THEN h."INDEX" || '-' || h."fullVisitorId" || '-' || h."visitId"
        END) AS "add_to_cart",
        COUNT(DISTINCT CASE
            WHEN h.hit:"eCommerceAction"."action_type" = '6'
            THEN h."INDEX" || '-' || h."fullVisitorId" || '-' || h."visitId"
        END) AS "purchases"
    FROM all_hits h
    GROUP BY 1
)
SELECT
    "month",
    ROUND("add_to_cart" * 100.0 / NULLIF("product_detail_views", 0), 2) AS "add_to_cart_rate",
    ROUND("purchases" * 100.0 / NULLIF("product_detail_views", 0), 2) AS "purchase_rate"
FROM monthly_actions
ORDER BY "month";