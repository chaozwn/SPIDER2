/*
 * sf_bq127.sql
 *
 * Question: For each publication family whose earliest publication was first
 * published in January 2015, provide the earliest publication date, the
 * distinct publication numbers, their country codes, the distinct CPC and IPC
 * codes, distinct families (ids) that cite and are cited by this publication
 * family. All lists are comma-separated values, sorted alphabetically.
 *
 * Assumptions:
 * - "earliest publication was first published in January 2015" means the
 *   minimum publication_date across all publications in a family falls in the
 *   range [20150101, 20150131] (yyyyMMdd integer format).
 * - "distinct families that cite this family" are derived from the cited_by
 *   JSON array in ABS_AND_EMB: when a publication_number appears in the
 *   cited_by array of another publication, that other publication's family
 *   "cites" this family.  The mapping from publication_number to family_id is
 *   resolved via the PUBLICATIONS table.
 * - "distinct families cited by this family" are derived from the citation
 *   JSON array in PUBLICATIONS: publication_numbers listed there are resolved
 *   to their family_ids via the PUBLICATIONS table.
 * - Non-patent literature (NPL) citations have an empty publication_number
 *   and are excluded.
 * - Self-citations (where a family cites itself) are included per the data.
 * - When a family has no CPC codes, no IPC codes, no citing families, or no
 *   cited families, the corresponding column is an empty string.
 * - ALL lists are sorted alphabetically (ascending).
 */

WITH
  -- Families whose earliest publication date is in January 2015
  jan2015_families AS (
    SELECT "family_id"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    GROUP BY "family_id"
    HAVING MIN("publication_date") BETWEEN 20150101 AND 20150131
  ),

  -- Base: earliest date, distinct publication numbers, distinct country codes
  family_base AS (
    SELECT
      f."family_id",
      MIN(f."publication_date") AS "earliest_date",
      LISTAGG(DISTINCT f."publication_number", ',')
        WITHIN GROUP (ORDER BY f."publication_number")
        AS "publication_numbers",
      LISTAGG(DISTINCT f."country_code", ',')
        WITHIN GROUP (ORDER BY f."country_code")
        AS "country_codes"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS f
    JOIN jan2015_families j ON f."family_id" = j."family_id"
    GROUP BY f."family_id"
  ),

  -- Distinct CPC codes per family (from JSON array)
  family_cpc AS (
    SELECT
      f."family_id",
      LISTAGG(DISTINCT c.value:"code"::STRING, ',')
        WITHIN GROUP (ORDER BY c.value:"code"::STRING)
        AS "cpc_codes"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS f
    JOIN jan2015_families j ON f."family_id" = j."family_id"
    JOIN LATERAL FLATTEN(input => PARSE_JSON(f."cpc")) c
    GROUP BY f."family_id"
  ),

  -- Distinct IPC codes per family (from JSON array)
  family_ipc AS (
    SELECT
      f."family_id",
      LISTAGG(DISTINCT i.value:"code"::STRING, ',')
        WITHIN GROUP (ORDER BY i.value:"code"::STRING)
        AS "ipc_codes"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS f
    JOIN jan2015_families j ON f."family_id" = j."family_id"
    JOIN LATERAL FLATTEN(input => PARSE_JSON(f."ipc")) i
    GROUP BY f."family_id"
  ),

  -- Families that CITE this family: resolved from ABS_AND_EMB.cited_by
  family_citing AS (
    SELECT
      jf."family_id",
      LISTAGG(DISTINCT citing_pubs."family_id", ',')
        WITHIN GROUP (ORDER BY citing_pubs."family_id")
        AS "citing_family_ids"
    FROM jan2015_families jf
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS fp
      ON jf."family_id" = fp."family_id"
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB ae
      ON fp."publication_number" = ae."publication_number"
    JOIN LATERAL FLATTEN(input => PARSE_JSON(ae."cited_by")) cb
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS citing_pubs
      ON cb.value:"publication_number"::STRING = citing_pubs."publication_number"
    WHERE cb.value:"publication_number"::STRING IS NOT NULL
      AND cb.value:"publication_number"::STRING != ''
    GROUP BY jf."family_id"
  ),

  -- Families CITED BY this family: resolved from PUBLICATIONS.citation
  family_cited AS (
    SELECT
      f."family_id",
      LISTAGG(DISTINCT cited_fam."family_id", ',')
        WITHIN GROUP (ORDER BY cited_fam."family_id")
        AS "cited_family_ids"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS f
    JOIN jan2015_families j ON f."family_id" = j."family_id"
    JOIN LATERAL FLATTEN(input => PARSE_JSON(f."citation")) c
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS cited_fam
      ON c.value:"publication_number"::STRING = cited_fam."publication_number"
    WHERE c.value:"publication_number"::STRING IS NOT NULL
      AND c.value:"publication_number"::STRING != ''
    GROUP BY f."family_id"
  )

-- Final output: one row per family, all lists comma-separated & sorted
SELECT
  b."family_id",
  b."earliest_date"                AS "earliest_publication_date",
  b."publication_numbers",
  b."country_codes",
  COALESCE(cpc."cpc_codes",   '')  AS "cpc_codes",
  COALESCE(ipc."ipc_codes",   '')  AS "ipc_codes",
  COALESCE(citing."citing_family_ids", '') AS "citing_family_ids",
  COALESCE(cited."cited_family_ids",  '') AS "cited_family_ids"
FROM family_base b
LEFT JOIN family_cpc   cpc    ON b."family_id" = cpc."family_id"
LEFT JOIN family_ipc   ipc    ON b."family_id" = ipc."family_id"
LEFT JOIN family_citing citing ON b."family_id" = citing."family_id"
LEFT JOIN family_cited cited  ON b."family_id" = cited."family_id"
ORDER BY b."family_id";