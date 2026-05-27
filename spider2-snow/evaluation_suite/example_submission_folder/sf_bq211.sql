-- sf_bq211.sql
--
-- Question:
-- Among patents granted between 2010 and 2023 in CN, how many of them belong
-- to families that have a total of over one distinct applications?
--
-- Answer: 161
--
-- Approach:
-- 1. Find all family_ids whose members collectively have >1 DISTINCT
--    application_number across the entire PUBLICATIONS table (all countries).
-- 2. Count how many CN patents granted between 2010-01-01 and 2023-12-31
--    belong to those families.
--
-- Assumptions:
-- - "granted between 2010 and 2023" is interpreted on year boundaries,
--   i.e. grant_date >= 2010-01-01 and grant_date <= 2023-12-31, using the
--   YYYYMMDD integer format stored in the grant_date column.
-- - "over one distinct applications" means >1 distinct application_number
--   for a family across all records in the dataset (not limited to CN or
--   to the 2010-2023 window).
-- - grant_date = 0 indicates no grant date (ungranted publication); these
--   are excluded.
-- - application_number is the column to count; it represents the original
--   application filing number associated with each publication record.

SELECT COUNT(*) AS "patent_count"
FROM "PATENTS"."PATENTS"."PUBLICATIONS" p
WHERE p."country_code" = 'CN'
  AND p."grant_date" >= 20100101
  AND p."grant_date" <= 20231231
  AND p."family_id" IN (
      SELECT "family_id"
      FROM "PATENTS"."PATENTS"."PUBLICATIONS"
      GROUP BY "family_id"
      HAVING COUNT(DISTINCT "application_number") > 1
  );