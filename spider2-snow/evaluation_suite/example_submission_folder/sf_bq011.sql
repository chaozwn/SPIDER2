/*
 * Business Question:
 *   How many distinct pseudo users (user_pseudo_id) had positive engagement time
 *   (> 0 engagement_time_msec) in the 7-day period ending on January 7, 2021 at
 *   23:59:59, but had no positive engagement time in the 2-day period ending on
 *   the same date (January 7, 2021 at 23:59:59)?
 *
 * Assumptions:
 *   - "7-day period ending on Jan 7, 2021" = Jan 1 through Jan 7, 2021 (inclusive).
 *   - "2-day period ending on the same date" = Jan 6 through Jan 7, 2021 (inclusive).
 *   - "Positive engagement time" = engagement_time_msec > 0, extracted from the
 *     event_params VARIANT via LATERAL FLATTEN.
 *   - Engagement time is an event-level parameter; a user is counted if they have
 *     AT LEAST ONE event with engagement_time_msec > 0 in the respective period.
 *   - Daily tables are named EVENTS_YYYYMMDD and cover the full 24-hour day.
 *
 * Result: 12,212 distinct user_pseudo_id.
 */

WITH

-- Users with positive engagement time in the 7-day period (Jan 1 – Jan 7, 2021)
users_7day AS (
    SELECT DISTINCT e.user_pseudo_id
    FROM (
        SELECT user_pseudo_id, event_params FROM GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210101
        UNION ALL
        SELECT user_pseudo_id, event_params FROM GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210102
        UNION ALL
        SELECT user_pseudo_id, event_params FROM GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210103
        UNION ALL
        SELECT user_pseudo_id, event_params FROM GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210104
        UNION ALL
        SELECT user_pseudo_id, event_params FROM GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210105
        UNION ALL
        SELECT user_pseudo_id, event_params FROM GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210106
        UNION ALL
        SELECT user_pseudo_id, event_params FROM GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210107
    ) e,
    TABLE(FLATTEN(input => e.event_params)) f
    WHERE f.value:key::STRING = 'engagement_time_msec'
      AND f.value:value.int_value::INT > 0
),

-- Users with positive engagement time in the 2-day period (Jan 6 – Jan 7, 2021)
users_2day AS (
    SELECT DISTINCT e.user_pseudo_id
    FROM (
        SELECT user_pseudo_id, event_params FROM GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210106
        UNION ALL
        SELECT user_pseudo_id, event_params FROM GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20210107
    ) e,
    TABLE(FLATTEN(input => e.event_params)) f
    WHERE f.value:key::STRING = 'engagement_time_msec'
      AND f.value:value.int_value::INT > 0
)

-- Final answer: count of users in 7-day set but NOT in 2-day set
SELECT COUNT(*) AS distinct_user_count
FROM users_7day u7
WHERE NOT EXISTS (
    SELECT 1
    FROM users_2day u2
    WHERE u2.user_pseudo_id = u7.user_pseudo_id
);