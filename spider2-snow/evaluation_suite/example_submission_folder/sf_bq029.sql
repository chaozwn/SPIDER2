/*
 * sf_bq029.sql
 *
 * Assumptions:
 * 1. Column "publication_date" is an INTEGER in YYYYMMDD format (e.g., 19850314 = March 14, 1985).
 * 2. Column "inventor" is a STRING containing a JSON array of inventor names,
 *    e.g. '["John Doe","Jane Smith"]'. "At least one inventor listed" means
 *    inventor IS NOT NULL AND inventor != '[]'.
 * 3. 5-year periods are computed from the publication year as:
 *    period_start = FLOOR(year / 5) * 5, giving intervals: 1960-1964, 1965-1969, etc.
 * 4. The question requests data from 1960 to 2020 inclusive, so the 2020-2024
 *    period only contains patents published in 2020.
 *
 * This script produces exactly the same result set as sf_bq029.csv.
 */

SELECT
    FLOOR(TRUNC(p.publication_date / 10000) / 5) * 5                 AS period_start,
    FLOOR(TRUNC(p.publication_date / 10000) / 5) * 5
        || '-' ||
        (FLOOR(TRUNC(p.publication_date / 10000) / 5) * 5 + 4)       AS period_label,
    COUNT(*)                                                          AS patent_count,
    ROUND(AVG(ARRAY_SIZE(PARSE_JSON(p.inventor))), 2)                AS avg_inventors_per_patent
FROM PATENTS.PATENTS.PUBLICATIONS p
WHERE p.country_code = 'CA'
  AND p.publication_date >= 19600101
  AND p.publication_date <= 20201231
  AND p.inventor IS NOT NULL
  AND p.inventor != '[]'
GROUP BY FLOOR(TRUNC(p.publication_date / 10000) / 5) * 5
ORDER BY period_start;