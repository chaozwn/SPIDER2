/*
 * sf_bq213.sql — Snowflake SQL
 * 
 * Question:
 *   What is the most common 4-digit IPC code among US B2 utility patents
 *   granted from June to August in 2022?
 *
 * Assumptions:
 *   1. "US B2" patents: country_code = 'US' AND kind_code = 'B2'.
 *   2. "granted from June to August 2022": grant_date is a NUMBER in
 *      YYYYMMDD format, filtered to [20220601, 20220831].
 *   3. "4-digit IPC code": the first 4 characters of each IPC code string.
 *   4. "Most common": the 4-digit IPC code that appears most frequently
 *      across all IPC entries of the qualifying patents. Each IPC entry
 *      (each element of the ipc array) counts as one occurrence.
 *   5. No single "main" IPC code is designated for most patents, so all
 *      IPC codes in the array are included equally.
 *
 * Output:
 *   A single row with two columns:
 *     - ipc4_code   VARCHAR  (the most frequent 4-digit IPC code)
 *     - occurrence_count NUMBER (how many times that code appeared)
 */

SELECT
    SUBSTR(ipc_u.value:"code", 1, 4) AS "ipc4_code",
    COUNT(*)                          AS "occurrence_count"
FROM PATENTS.PATENTS.PUBLICATIONS,
     LATERAL FLATTEN(input => "ipc") AS ipc_u
WHERE "country_code" = 'US'
  AND "kind_code"    = 'B2'
  AND "grant_date"  >= 20220601
  AND "grant_date"  <= 20220831
GROUP BY "ipc4_code"
ORDER BY "occurrence_count" DESC
LIMIT 1;