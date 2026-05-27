-- sf_bq209.sql
--
-- Business Question:
-- "Can you calculate the number of utility patents that were granted in 2010
--  and have exactly one forward citation within a 10-year window following
--  their application/filing date? For this analysis, forward citations should
--  be counted as distinct citing application numbers that cited the patent
--  within 10 years after the patent's own filing date."
--
-- Assumptions:
-- 1. "Utility patents" are defined as patents whose kind_code starts with 'B'
--    (granted patent) or 'C' (granted reexamination certificate), following
--    WIPO ST.16 standard for granted patent documents. This excludes design
--    patents (S), plant patents (P), utility models (U,Y), and published
--    applications (A).
-- 2. "Granted in 2010" means grant_date between 2010-01-01 and 2010-12-31
--    (inclusive), stored as integer YYYYMMDD.
-- 3. The 10-year forward-citation window is measured from the patent's own
--    filing_date. A citing patent's application must have a filing_date that
--    is >= the target's filing_date and <= filing_date + 10 years.
-- 4. Forward citations are counted as DISTINCT citing application numbers,
--    as explicitly stated in the question.
-- 5. Only patents with a valid (non-zero) filing_date are included.

WITH
-- Step 1: Utility patents granted in calendar year 2010
utility_patents_2010 AS (
    SELECT
        "publication_number",
        "filing_date"
    FROM "PATENTS"."PATENTS"."PUBLICATIONS"
    WHERE "grant_date" >= 20100101
      AND "grant_date" < 20110101
      AND SUBSTR("kind_code", 1, 1) IN ('B', 'C')
      AND "filing_date" > 0
),

-- Step 2: All citation edges — each citing patent's publication flattens its
--         citation JSON array into one row per cited publication.
all_citations AS (
    SELECT
        citing."publication_number" AS "citing_pub",
        citing."filing_date" AS "citing_filing_date",
        citing."application_number" AS "citing_app_number",
        c.value:"publication_number"::VARCHAR AS "cited_pub"
    FROM "PATENTS"."PATENTS"."PUBLICATIONS" citing,
         LATERAL FLATTEN(input => citing."citation") c
    WHERE citing."filing_date" > 0
      AND c.value:"publication_number"::VARCHAR IS NOT NULL
      AND c.value:"publication_number"::VARCHAR != ''
),

-- Step 3: Forward citations — join utility patents with citation edges where
--         the patent's publication_number appears in another patent's citation
--         list, and the citing application was filed within 10 years.
forward_cites AS (
    SELECT
        p."publication_number" AS "target_pub",
        fc."citing_app_number"
    FROM utility_patents_2010 p
    INNER JOIN all_citations fc
        ON fc."cited_pub" = p."publication_number"
    WHERE fc."citing_filing_date" >= p."filing_date"
      AND TO_DATE(fc."citing_filing_date"::VARCHAR, 'YYYYMMDD')
          <= DATEADD(YEAR, 10, TO_DATE(p."filing_date"::VARCHAR, 'YYYYMMDD'))
),

-- Step 4: Count distinct citing application numbers per target patent
citation_counts AS (
    SELECT
        "target_pub",
        COUNT(DISTINCT "citing_app_number") AS "fwd_cite_count"
    FROM forward_cites
    GROUP BY "target_pub"
)

-- Final answer: how many utility patents have exactly 1 distinct forward
-- citation within the 10-year window?
SELECT COUNT(*) AS "utility_patent_count"
FROM citation_counts
WHERE "fwd_cite_count" = 1;