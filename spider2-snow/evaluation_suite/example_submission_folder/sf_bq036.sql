/*
 * sf_bq036.sql
 *
 * Question: What was the average number of GitHub commits made per month
 * in 2016 for repositories containing Python code?
 *
 * Assumptions:
 * 1. "Repositories containing Python code" means any repository whose
 *    LANGUAGES.language JSON array includes an element with "name": "Python".
 * 2. Commit date is determined by the author timestamp (author.time_sec field).
 * 3. The average is computed as:
 *        SUM(monthly_commits) / COUNT(DISTINCT repo-month combinations)
 *    i.e. over every (repo, month) pair that had at least one commit in 2016.
 *
 * Result: 21.17
 */

SELECT
    ROUND(SUM(monthly_commits) * 1.0 / COUNT(*), 2) AS avg_commits_per_month
FROM (
    SELECT
        c.repo_name,
        DATE_TRUNC('MONTH', TO_TIMESTAMP(c.author:time_sec::INT)) AS month,
        COUNT(*) AS monthly_commits
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
    INNER JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l
        ON c.repo_name = l.repo_name
    WHERE EXISTS (
        SELECT 1
        FROM LATERAL FLATTEN(INPUT => l.language) f
        WHERE f.value:name = 'Python'
    )
    AND YEAR(TO_TIMESTAMP(c.author:time_sec::INT)) = 2016
    GROUP BY c.repo_name, DATE_TRUNC('MONTH', TO_TIMESTAMP(c.author:time_sec::INT))
) t;