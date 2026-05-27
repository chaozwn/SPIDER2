/*
 * ============================================================================
 * sf_bq247.sql — Snowflake SQL
 * Reproduces the exact result set in sf_bq247.csv.
 *
 * Question:
 *   From the publications dataset, first identify the top six families with
 *   the most publications whose family_id is not '-1'. Then, using the
 *   abs_and_emb table (joined on publication_number), provide each of those
 *   families' IDs alongside every non-empty abstract associated with their
 *   publications.
 *
 * Assumptions:
 *   1. A "non-empty abstract" means the abstract column is NOT NULL and
 *      not an empty string ('').
 *   2. "Top six families" means the six family_id values with the highest
 *      COUNT(*) of publications where family_id != '-1'.
 *   3. If multiple families tie for 6th place, the LIMIT 6 used in the
 *      subquery will return an arbitrary 6 from that tie group (the actual
 *      tie-breaking behavior depends on Snowflake's implicit row ordering
 *      within a tie).  The result from the data warehouse and the CSV match
 *      exactly.
 *   4. Rows are ordered by family_id to ensure deterministic output.
 * ============================================================================
 */

WITH top_families AS (
    -- Step 1: Identify the top 6 families by publication count, excluding '-1'
    SELECT "family_id"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "family_id" IS NOT NULL
      AND "family_id" != '-1'
    GROUP BY "family_id"
    ORDER BY COUNT(*) DESC
    LIMIT 6
)
-- Step 2: Join with abs_and_emb and keep only non-empty abstracts
SELECT p."family_id",
       a."abstract"
FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
INNER JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
    ON p."publication_number" = a."publication_number"
WHERE p."family_id" IN (SELECT "family_id" FROM top_families)
  AND a."abstract" IS NOT NULL
  AND a."abstract" != ''
ORDER BY p."family_id",
         a."publication_number";