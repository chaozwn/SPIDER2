/*
 * =============================================================================
 * sf_bq128.sql
 * =============================================================================
 * Business Question:
 *   Retrieve patent title, abstract, publication date, backward citation count
 *   (citations before filing date), and forward citation count (citations within
 *   5 years after publication) for U.S. patents filed between 2014-01-01 and
 *   2014-02-01 that belong to chemistry/biology/medical-related CPC categories.
 *
 * CPC Filter (from reference document):
 *   Subsection ID in C5–C13 (Chemistry-related subsections), OR
 *   Group ID in: A01G, A01H, A61K, A61P, A61Q, B01F, B01J, B81B, B82B, B82Y,
 *   G01N, G16H (Agriculture/Medical/Nano/Testing categories)
 *
 * Assumptions:
 *   1. "Backward citations" = US patent citations (USPATENTCITATION) where the
 *      cited patent's publication date < the current patent's filing date, plus
 *      foreign patent citations (FOREIGNCITATION) where the citation date is
 *      valid and < the filing date.
 *   2. "Forward citations (within 5 years)" = US patents (via USPATENTCITATION)
 *      that cite the current patent, where the citing patent's publication date
 *      is >= the current patent's publication date and <= that date + 5 years.
 *   3. Date ordering uses string comparison ('YYYY-MM-DD' is sortable) for the
 *      citation join conditions, matching the data format in the source tables.
 *   4. FOREIGNCITATION rows with malformed dates (e.g. '0000-00-01') are
 *      excluded from the backward count because the date cannot be verified.
 *   5. A patent belongs to the target CPC categories if ANY of its CPC_CURRENT
 *      rows matches the filter; patents with no matching CPC are excluded.
 *
 * Output shape:
 *   One row per patent, columns: title, abstract, publication_date,
 *   backward_citation_count, forward_citation_count.
 * =============================================================================
 */

WITH
-- Step 1: Identify target patents (US, filing date in range, CPC filter)
base_patents AS (
    SELECT
        p."id",
        p."title",
        p."abstract",
        p."date" AS "publication_date",
        a."date" AS "filing_date"
    FROM "PATENTSVIEW"."PATENTSVIEW"."PATENT" p
    INNER JOIN "PATENTSVIEW"."PATENTSVIEW"."APPLICATION" a
        ON p."id" = a."patent_id"
    WHERE
        p."country" = 'US'
        AND a."date" >= '2014-01-01'
        AND a."date" <= '2014-02-01'
        AND EXISTS (
            SELECT 1
            FROM "PATENTSVIEW"."PATENTSVIEW"."CPC_CURRENT" cc
            WHERE cc."patent_id" = p."id"
              AND (
                  (cc."subsection_id" >= 'C5' AND cc."subsection_id" <= 'C13')
                  OR cc."group_id" IN (
                      'A01G', 'A01H', 'A61K', 'A61P', 'A61Q',
                      'B01F', 'B01J', 'B81B', 'B82B', 'B82Y',
                      'G01N', 'G16H'
                  )
              )
        )
),

-- Step 2: Backward citations (citations before filing date)
backward AS (
    SELECT
        bp."id",
        COUNT(DISTINCT uc."citation_id")
        + COUNT(DISTINCT fc."uuid") AS "backward_count"
    FROM base_patents bp
    LEFT JOIN "PATENTSVIEW"."PATENTSVIEW"."USPATENTCITATION" uc
        ON  bp."id" = uc."patent_id"
        AND uc."date" < bp."filing_date"
    LEFT JOIN "PATENTSVIEW"."PATENTSVIEW"."FOREIGNCITATION" fc
        ON  bp."id" = fc."patent_id"
        AND fc."date" IS NOT NULL
        AND TRY_CAST(fc."date" AS DATE) IS NOT NULL
        AND TRY_CAST(fc."date" AS DATE) < TRY_CAST(bp."filing_date" AS DATE)
    GROUP BY bp."id"
),

-- Step 3: Forward citations (citing patents published within 5 years after)
forward AS (
    SELECT
        bp."id",
        COUNT(DISTINCT uc."patent_id") AS "forward_count"
    FROM base_patents bp
    LEFT JOIN "PATENTSVIEW"."PATENTSVIEW"."USPATENTCITATION" uc
        ON  bp."id" = uc."citation_id"
    LEFT JOIN "PATENTSVIEW"."PATENTSVIEW"."PATENT" citing
        ON  uc."patent_id" = citing."id"
        AND citing."date" IS NOT NULL
        AND citing."date" >= bp."publication_date"
        AND citing."date" <= CAST(DATEADD(YEAR, 5, CAST(bp."publication_date" AS DATE)) AS VARCHAR)
    GROUP BY bp."id"
)

-- Final output: one row per patent with all requested columns
SELECT
    bp."title",
    bp."abstract",
    bp."publication_date",
    COALESCE(b."backward_count", 0) AS "backward_citation_count",
    COALESCE(f."forward_count", 0)  AS "forward_citation_count"
FROM base_patents bp
LEFT JOIN backward b ON bp."id" = b."id"
LEFT JOIN forward  f ON bp."id" = f."id"
ORDER BY bp."id";