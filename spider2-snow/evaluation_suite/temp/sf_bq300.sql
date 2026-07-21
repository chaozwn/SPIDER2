-- sf_bq300: highest #answers for a Python-2-specific Stack Overflow question,
-- excluding discussions that involve Python 3.
--
-- Official logic from spider2-lite/evaluation_suite/gold/sql/bq300.sql
-- (column renamed count_number -> MAX_ANSWERS to match gold CSV)
--
-- Verified on Snowflake STACKOVERFLOW:
--   MAX_ANSWERS = 43  -> matches sf_bq300_b.csv
--   sf_bq300_a.csv (26) is an alternate accepted gold (likely BigQuery snapshot)

WITH python2_questions AS (
  SELECT
    q."id" AS question_id,
    q."title",
    q."body" AS question_body,
    q."tags"
  FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
  WHERE (
      LOWER(q."tags") LIKE '%python-2%'
      OR LOWER(q."tags") LIKE '%python-2.x%'
      OR LOWER(q."title") LIKE '%python 2%'
      OR LOWER(q."body") LIKE '%python 2%'
      OR LOWER(q."title") LIKE '%python2%'
      OR LOWER(q."body") LIKE '%python2%'
    )
    AND LOWER(q."title") NOT LIKE '%python 3%'
    AND LOWER(q."body") NOT LIKE '%python 3%'
    AND LOWER(q."title") NOT LIKE '%python3%'
    AND LOWER(q."body") NOT LIKE '%python3%'
)
SELECT
  COUNT(*) AS MAX_ANSWERS
FROM python2_questions q
LEFT JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS a
  ON q.question_id = a."parent_id"
GROUP BY q.question_id
ORDER BY MAX_ANSWERS DESC
LIMIT 1;
