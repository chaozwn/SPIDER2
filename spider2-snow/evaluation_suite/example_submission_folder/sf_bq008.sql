-- Assumption: interpreted "visited next" as the next PAGE hit after a /home* PAGE hit within the same session; non-PAGE hits are ignored.
WITH page_hits AS (
    SELECT
        "fullVisitorId" AS full_visitor_id,
        "visitId" AS visit_id,
        h.value:hitNumber::NUMBER AS hit_number,
        h.value:page.pagePath::STRING AS page_path,
        h.value:time::NUMBER AS hit_time_ms
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170101,
         LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%'
      AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170102, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170103, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170104, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170105, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170106, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170107, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170108, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170109, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170110, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170111, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170112, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170113, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170114, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170115, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170116, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170117, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170118, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170119, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170120, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170121, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170122, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170123, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170124, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170125, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170126, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170127, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170128, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170129, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170130, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
    UNION ALL
    SELECT "fullVisitorId", "visitId", h.value:hitNumber::NUMBER, h.value:page.pagePath::STRING, h.value:time::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170131, LATERAL FLATTEN(input => "hits") h
    WHERE "trafficSource":campaign::STRING ILIKE '%Data Share%' AND h.value:type::STRING = 'PAGE'
),
sequenced_page_hits AS (
    SELECT
        page_path AS home_page,
        LEAD(page_path) OVER (
            PARTITION BY full_visitor_id, visit_id
            ORDER BY hit_number
        ) AS next_page,
        (
            LEAD(hit_time_ms) OVER (
                PARTITION BY full_visitor_id, visit_id
                ORDER BY hit_number
            ) - hit_time_ms
        ) / 1000.0 AS time_on_home_seconds
    FROM page_hits
),
home_transitions AS (
    SELECT
        next_page,
        time_on_home_seconds
    FROM sequenced_page_hits
    WHERE home_page LIKE '/home%'
      AND next_page IS NOT NULL
),
page_summary AS (
    SELECT
        next_page,
        COUNT(*) AS transition_count,
        MAX(time_on_home_seconds) AS max_time_on_home_seconds
    FROM home_transitions
    GROUP BY next_page
)
SELECT
    next_page AS "next_page",
    max_time_on_home_seconds AS "max_time_on_home_seconds"
FROM page_summary
ORDER BY transition_count DESC, next_page ASC
LIMIT 1;