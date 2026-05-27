/*
 * Assumptions:
 * 1. "Import statements enclosed in parentheses" refers to any occurrence of
 *    `import(` in the file content (e.g. `import("...")`, `Cu.import("...")`).
 * 2. Content is split by newlines to handle multi-line import statements.
 * 3. Package names are double-quoted strings that appear within `import(...)`.
 *    The regex `import\([^)]*"([^"]+)"[^)]*\)` extracts the LAST double-quoted
 *    string before the closing `)`. This handles both single-arg imports like
 *    `import("//foo.gni")` and multi-arg imports like `import("npm","x","0.1.*")`
 *    (which extracts "0.1.*" since the regex is greedy for `[^)]*`).
 * 4. The final answer removes the quotation marks (handled automatically by
 *    capturing group 1 of the regex).
 * 5. Null or empty results are excluded before counting.
 * 6. When frequencies tie, alphabetical order is used as secondary sort.
 */

WITH
-- Step 1: Split file content by newlines to break multi-line imports
content_lines AS (
    SELECT
        sc.id,
        sc.sample_path,
        LTRIM(f.value) AS line
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
    LATERAL FLATTEN(INPUT => SPLIT(sc.content, '\n')) f
),

-- Step 2: Keep only lines containing import(...
import_lines AS (
    SELECT id, sample_path, line
    FROM content_lines
    WHERE line LIKE '%import(%'
),

-- Step 3: Extract the double-quoted package name from within import(...)
extracted AS (
    SELECT
        id,
        sample_path,
        REGEXP_SUBSTR(
            line,
            'import\\([^)]*"([^"]+)"[^)]*\\)',
            1,          -- start position
            1,          -- occurrence
            'e',        -- extract capture group
            1           -- capture group index
        ) AS package_name
    FROM import_lines
)

-- Step 4: Count, filter nulls, order descending, limit to top 10
SELECT
    package_name,
    COUNT(*) AS frequency
FROM extracted
WHERE package_name IS NOT NULL
  AND package_name != ''
GROUP BY package_name
ORDER BY frequency DESC, package_name ASC
LIMIT 10;