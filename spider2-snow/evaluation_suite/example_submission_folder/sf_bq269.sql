/*
 * =============================================================================
 * sf_bq269.sql — Snowflake SQL answer script
 * =============================================================================
 *
 * Business Question:
 *   Between June 1, 2017, and July 31, 2017, consider only sessions that have
 *   non-null pageviews. Classify each session as 'purchase' if it has at least
 *   one transaction, or 'non_purchase' otherwise. For each month, sum each
 *   visitor's total pageviews under each classification, then compute the
 *   average pageviews per visitor for both purchase and non_purchase groups in
 *   each month, and present the results side by side.
 *
 * Assumptions:
 *   - "non-null pageviews" means totals:pageviews IS NOT NULL and non-zero.
 *   - "at least one transaction" means totals:transactions > 0.
 *   - Month is extracted from the 'date' column as YYYYMM.
 *   - Daily tables follow the naming pattern GA_SESSIONS_YYYYMMDD.
 *
 * Output columns:
 *   month                    | VARCHAR   | YYYYMM format
 *   avg_pageviews_purchase   | FLOAT     | avg pageviews per visitor (purchase group)
 *   avg_pageviews_non_purchase | FLOAT   | avg pageviews per visitor (non-purchase group)
 *
 * Order: ascending by month.
 * =============================================================================
 */

WITH

-- ============================================================
-- Step 1: Combine all daily tables for June 1 – July 31, 2017
-- ============================================================
all_sessions AS (
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170601
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170602
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170603
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170604
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170605
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170606
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170607
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170608
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170609
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170610
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170611
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170612
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170613
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170614
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170615
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170616
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170617
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170618
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170619
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170620
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170621
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170622
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170623
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170624
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170625
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170626
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170627
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170628
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170629
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170630
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170701
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170702
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170703
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170704
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170705
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170706
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170707
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170708
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170709
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170710
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170711
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170712
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170713
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170714
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170715
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170716
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170717
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170718
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170719
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170720
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170721
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170722
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170723
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170724
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170725
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170726
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170727
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170728
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170729
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170730
    UNION ALL
    SELECT fullVisitorId, date, totals
    FROM GOOGLE_ANALYTICS_SAMPLE.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170731
),

-- ============================================================
-- Step 2: Filter sessions with non-null pageviews, classify,
--          and extract month
-- ============================================================
sessions_filtered AS (
    SELECT
        fullVisitorId,
        SUBSTR(date, 1, 6)                                                              AS month,
        CAST(GET_PATH(totals, 'pageviews') AS INTEGER)                                  AS pageviews,
        IFF(
            CAST(NULLIF(GET_PATH(totals, 'transactions'), '') AS INTEGER) > 0,
            'purchase',
            'non_purchase'
        )                                                                               AS classification
    FROM all_sessions
    WHERE GET_PATH(totals, 'pageviews') IS NOT NULL
      AND CAST(GET_PATH(totals, 'pageviews') AS INTEGER) > 0
),

-- ============================================================
-- Step 3: Sum pageviews per visitor per month per classification
-- ============================================================
visitor_pageviews AS (
    SELECT
        month,
        classification,
        fullVisitorId,
        SUM(pageviews) AS total_pageviews
    FROM sessions_filtered
    GROUP BY month, classification, fullVisitorId
),

-- ============================================================
-- Step 4: Compute average pageviews per visitor per group
-- ============================================================
avg_by_group AS (
    SELECT
        month,
        classification,
        AVG(total_pageviews) AS avg_pageviews_per_visitor
    FROM visitor_pageviews
    GROUP BY month, classification
)

-- ============================================================
-- Final: Pivot purchase and non_purchase side by side
-- ============================================================
SELECT
    month,
    MAX(CASE WHEN classification = 'purchase' THEN avg_pageviews_per_visitor END)     AS avg_pageviews_purchase,
    MAX(CASE WHEN classification = 'non_purchase' THEN avg_pageviews_per_visitor END) AS avg_pageviews_non_purchase
FROM avg_by_group
GROUP BY month
ORDER BY month ASC;