/*
 * sf_bq027.sql
 * 
 * Question:
 * For patents granted between 2010 and 2018, provide the publication number of
 * each patent and the number of backward citations it has received in the SEA
 * category.
 *
 * Assumptions:
 * 1. "Granted" is determined by the "grant_date" column (numeric YYYYMMDD format).
 *    Patents with grant_date >= 20100101 AND grant_date <= 20181231 are included.
 * 2. "Backward citations in the SEA category" are citation entries within the
 *    "citation" VARIANT column whose "category" field equals 'SEA'.
 * 3. Patents with zero SEA citations are included (count = 0).
 * 4. Result is ordered by publication_number alphabetically.
 *
 * Output columns:
 *   - publication_number  : The patent publication number (VARCHAR)
 *   - sea_citation_count  : Number of SEA-category backward citations (NUMBER)
 */

SELECT
    p."publication_number" AS "publication_number",
    COALESCE(sea."sea_count", 0) AS "sea_citation_count"
FROM "PATENTS"."PATENTS"."PUBLICATIONS" p
LEFT JOIN (
    SELECT
        inner_p."publication_number" AS "pub_num",
        COUNT(c.value:"category"::VARCHAR) AS "sea_count"
    FROM "PATENTS"."PATENTS"."PUBLICATIONS" inner_p,
    LATERAL FLATTEN(input => inner_p."citation") c
    WHERE inner_p."grant_date" >= 20100101
      AND inner_p."grant_date" <= 20181231
      AND c.value:"category"::VARCHAR = 'SEA'
    GROUP BY inner_p."publication_number"
) sea
    ON p."publication_number" = sea."pub_num"
WHERE p."grant_date" >= 20100101
  AND p."grant_date" <= 20181231
ORDER BY p."publication_number";