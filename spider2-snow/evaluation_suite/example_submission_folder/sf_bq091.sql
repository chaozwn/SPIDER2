/*
 * =============================================================================
 * Business Question:
 *   In which year did the assignee with the most applications in the patent
 *   category 'A61' file the most?
 *
 * Answer: 1997
 *
 * Assumptions:
 *   1. A patent is counted as an "A61 application" if any code in its CPC
 *      (Cooperative Patent Classification) VARIANT column starts with 'A61'.
 *   2. The "assignee" is extracted from the "assignee_harmonized" VARIANT
 *      column as the "name" field of each array element.
 *   3. "Applications" are counted by DISTINCT publication_number per patent
 *      family member.
 *   4. A patent's filing year is derived from the "filing_date" integer column
 *      (format YYYYMMDD) by extracting the year component (FLOOR / 10000).
 *      Records with filing_date = 0 (unknown) are excluded.
 *   5. In case of ties for the most A61 applications, the top assignee is
 *      determined by alphabetical order (via MIN/ROW_NUMBER). This is defensive
 *      but the data shows PROCTER & GAMBLE as uniquely top.
 *
 * Schema: PATENTS.PATENTS.PUBLICATIONS
 * =============================================================================
 */

WITH
-- Step 1: Count distinct A61 publications per assignee
assignee_a61_counts AS (
    SELECT
        a.value:"name"::VARCHAR AS assignee_name,
        COUNT(DISTINCT p.publication_number) AS application_count
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p.cpc) c,
         LATERAL FLATTEN(input => p.assignee_harmonized) a
    WHERE c.value:"code" LIKE 'A61%'
      AND p.assignee_harmonized IS NOT NULL
      AND p.assignee_harmonized != '[]'
    GROUP BY a.value:"name"::VARCHAR
),

-- Step 2: Pick the assignee with the most applications (break ties by name)
top_assignee AS (
    SELECT assignee_name
    FROM assignee_a61_counts
    ORDER BY application_count DESC, assignee_name ASC
    LIMIT 1
),

-- Step 3: Count A61 publications per year for the top assignee
assignee_year_counts AS (
    SELECT
        FLOOR(p.filing_date / 10000) AS filing_year,
        COUNT(DISTINCT p.publication_number) AS application_count
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p.cpc) c,
         LATERAL FLATTEN(input => p.assignee_harmonized) a
    WHERE c.value:"code" LIKE 'A61%'
      AND a.value:"name"::VARCHAR = (SELECT assignee_name FROM top_assignee)
      AND p.filing_date > 0
    GROUP BY FLOOR(p.filing_date / 10000)
)

-- Step 4: Return the year with the highest application count
SELECT filing_year
FROM assignee_year_counts
ORDER BY application_count DESC
LIMIT 1;