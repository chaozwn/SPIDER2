/*
 * =============================================================================
 * sf_bq033.sql
 * =============================================================================
 * Question:
 *   How many U.S. publications related to IoT (where the abstract includes
 *   the phrase 'internet of things') were filed each month from 2008 to 2022,
 *   including months with no filings?
 *
 * Output shape:
 *   180 rows (12 months × 15 years), 3 columns:
 *     year, month, publication_count
 *
 * Assumptions:
 *   1. "filed" refers to the filing_date column in the PUBLICATIONS table.
 *   2. "U.S." is defined as country_code = 'US'.
 *   3. "abstract includes the phrase 'internet of things'" is matched via
 *      a case-insensitive substring search on the English abstract text
 *      extracted from the VARIANT column abstract_localized[0].text.
 *      The text is cast to VARCHAR and searched with LIKE '%internet of things%'.
 *   4. The date range is inclusive of the full years 2008 through 2022
 *      (2008-01-01 through 2022-12-31).
 *   5. Months with no filings are included via a recursive calendar spine.
 *
 * Source table: PATENTS.PATENTS.PUBLICATIONS (Snowflake)
 * =============================================================================
 */

WITH RECURSIVE
    -- Full month spine: first day of every month from 2008-01-01 to 2022-12-01
    month_spine AS (
        SELECT DATE('2008-01-01') AS month_start
        UNION ALL
        SELECT DATEADD(MONTH, 1, month_start)
        FROM month_spine
        WHERE month_start < DATE('2022-12-01')
    ),

    -- IoT-related U.S. publications within the date range, aggregated by month
    iot_pub AS (
        SELECT
            DATE_TRUNC('MONTH', TO_DATE(p."filing_date"::VARCHAR, 'YYYYMMDD'))
                AS filing_month,
            COUNT(*) AS cnt
        FROM "PATENTS"."PATENTS"."PUBLICATIONS" p
        WHERE p."country_code" = 'US'
          AND p."abstract_localized" IS NOT NULL
          AND p."abstract_localized" != '[]'
          AND LOWER(p."abstract_localized"[0]."text"::VARCHAR)
              LIKE '%internet of things%'
          AND p."filing_date" >= 20080101
          AND p."filing_date" <= 20221231
        GROUP BY filing_month
    )

-- Final result: each row is one calendar month with its publication count
SELECT
    YEAR(ms.month_start)  AS year,
    MONTH(ms.month_start) AS month,
    COALESCE(i.cnt, 0)    AS publication_count
FROM month_spine ms
LEFT JOIN iot_pub i
    ON ms.month_start = i.filing_month
ORDER BY ms.month_start;