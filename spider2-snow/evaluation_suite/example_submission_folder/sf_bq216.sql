/*
 * ============================================================================
 * sf_bq216.sql
 * ------------
 * Question:
 *   Identify the top five patents filed in the same year as US-9741766-B2 that
 *   are most similar to it based on technological similarities. Please provide
 *   the publication numbers.
 *
 * Approach:
 *   - Determine the filing year of US-9741766-B2 from publications table.
 *   - Retrieve the 64-dimensional text embedding (embedding_v1) of the target
 *     patent from the google_patents_research.publications table.
 *   - Retrieve embeddings of all other patents filed in the same year.
 *   - Compute dot-product similarity between the target's embedding vector and
 *     each candidate's embedding vector.
 *   - Return the 5 candidates with the highest similarity scores, ordered from
 *     most similar to least similar.
 *
 * Assumptions:
 *   - "filed in the same year" is based on the filing_date column (the YYYYMMDD
 *     integer) in patents.publications. The year extracted is 2016.
 *   - "technological similarities" is measured via the dot product of the
 *     pre-computed embedding_v1 vectors — higher dot product = more similar,
 *     as described in the patents_info.md reference document.
 *   - The target patent US-9741766-B2 is excluded from the result set.
 *   - Only patents that have a non-null embedding_v1 are considered.
 *
 * Output:
 *   One column (publication_number), 5 rows, ordered by descending similarity.
 * ============================================================================
 */

-- Step 1: Determine the filing year of the target patent
WITH target_year AS (
    SELECT
        FLOOR(p.filing_date / 10000) AS filing_year
    FROM `patents-public-data.patents.publications` p
    WHERE p.publication_number = 'US-9741766-B2'
),

-- Step 2: Flatten the target patent's embedding vector into (index, value) rows
target_flat AS (
    SELECT
        f.INDEX AS idx,
        f.VALUE::FLOAT AS val
    FROM `patents-public-data.google_patents_research.publications` t,
        LATERAL FLATTEN(input => t.embedding_v1) f
    WHERE t.publication_number = 'US-9741766-B2'
),

-- Step 3: Select candidate patents (same filing year, excluding target, with embeddings)
candidates AS (
    SELECT
        a.publication_number,
        a.embedding_v1
    FROM `patents-public-data.google_patents_research.publications` a
    INNER JOIN `patents-public-data.patents.publications` p
        ON a.publication_number = p.publication_number
    CROSS JOIN target_year ty
    WHERE FLOOR(p.filing_date / 10000) = ty.filing_year
      AND a.publication_number != 'US-9741766-B2'
      AND a.embedding_v1 IS NOT NULL
),

-- Step 4: Flatten each candidate's embedding vector
candidates_flat AS (
    SELECT
        c.publication_number,
        f.INDEX AS idx,
        f.VALUE::FLOAT AS val
    FROM candidates c,
        LATERAL FLATTEN(input => c.embedding_v1) f
)

-- Step 5: Compute dot product similarity and return the top 5
SELECT
    cf.publication_number
FROM candidates_flat cf
INNER JOIN target_flat tf
    ON cf.idx = tf.idx
GROUP BY cf.publication_number
ORDER BY SUM(tf.val * cf.val) DESC
LIMIT 5;