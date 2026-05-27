/*
 * Question: For United States utility patents under the B2 classification
 * granted between June and September of 2022, identify the most frequent
 * 4-digit IPC code for each patent. Then, list the publication numbers and
 * IPC4 codes of patents where this code appears 10 or more times.
 *
 * Assumptions:
 * - "granted between June and September of 2022" is interpreted using the
 *   publication_date column (which matches grant_date for US B2 records in
 *   this dataset). Date range is inclusive: 2022-06-01 to 2022-09-30.
 * - "most frequent 4-digit IPC code for each patent" means the IPC4 prefix
 *   (first 4 characters of the IPC code) that appears the most times within
 *   that patent's IPC list.
 * - "identify ... Then, list" means the final output is one row per patent
 *   matching the filter, showing only the publication_number and the IPC4
 *   code that was its most frequent.
 *
 * Final SELECT: produces 7 rows, ordered by publication_number.
 */

WITH ipc4_per_patent AS (
  SELECT
    t."publication_number",
    SUBSTRING(ipc_u.value:"code", 1, 4) AS "ipc4",
    COUNT(*) AS "ipc4_count"
  FROM "PATENTS"."PATENTS"."PUBLICATIONS" t,
  LATERAL FLATTEN(input => t."ipc") ipc_u
  WHERE t."country_code" = 'US'
    AND t."kind_code" = 'B2'
    AND t."publication_date" BETWEEN 20220601 AND 20220930
    AND ipc_u.value:"code" IS NOT NULL
    AND TRIM(ipc_u.value:"code") != ''
  GROUP BY t."publication_number", SUBSTRING(ipc_u.value:"code", 1, 4)
),
max_per_patent AS (
  SELECT
    "publication_number",
    MAX("ipc4_count") AS "max_ipc4_count"
  FROM ipc4_per_patent
  GROUP BY "publication_number"
  HAVING MAX("ipc4_count") >= 10
)
SELECT
  i."publication_number",
  i."ipc4"
FROM ipc4_per_patent i
INNER JOIN max_per_patent m
  ON i."publication_number" = m."publication_number"
  AND i."ipc4_count" = m."max_ipc4_count"
ORDER BY i."publication_number", i."ipc4";