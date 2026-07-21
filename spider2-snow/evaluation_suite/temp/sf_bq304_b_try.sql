WITH tags_to_use AS (
  SELECT column1 AS tag, column2 AS idx FROM VALUES
    ('android-layout',0),('android-activity',1),('android-intent',2),('android-edittext',3),
    ('android-fragments',4),('android-recyclerview',5),('listview',6),('android-actionbar',7),
    ('google-maps',8),('android-asynctask',9)
),
android_how_to_questions AS (
  SELECT PQ."id", PQ."title", PQ."tags", PQ."view_count", PQ."creation_date"
  FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS PQ
  WHERE (
    CONTAINS('|' || PQ."tags" || '|', '|android-layout|')
    OR CONTAINS('|' || PQ."tags" || '|', '|android-activity|')
    OR CONTAINS('|' || PQ."tags" || '|', '|android-intent|')
    OR CONTAINS('|' || PQ."tags" || '|', '|android-edittext|')
    OR CONTAINS('|' || PQ."tags" || '|', '|android-fragments|')
    OR CONTAINS('|' || PQ."tags" || '|', '|android-recyclerview|')
    OR CONTAINS('|' || PQ."tags" || '|', '|listview|')
    OR CONTAINS('|' || PQ."tags" || '|', '|android-actionbar|')
    OR CONTAINS('|' || PQ."tags" || '|', '|google-maps|')
    OR CONTAINS('|' || PQ."tags" || '|', '|android-asynctask|')
  )
  AND (
    REGEXP_LIKE(LOWER(PQ."title"), '.*(^|[^a-z])how([^a-z]|$).*')
    OR REGEXP_LIKE(LOWER(PQ."body"), '.*(^|[^a-z])how([^a-z]|$).*')
  )
  AND NOT (
    LOWER(PQ."title") LIKE '%fail%' OR LOWER(PQ."title") LIKE '%problem%' OR LOWER(PQ."title") LIKE '%error%'
    OR LOWER(PQ."title") LIKE '%wrong%' OR LOWER(PQ."title") LIKE '%fix%' OR LOWER(PQ."title") LIKE '%bug%'
    OR LOWER(PQ."title") LIKE '%issue%' OR LOWER(PQ."title") LIKE '%solve%' OR LOWER(PQ."title") LIKE '%trouble%'
  )
  AND NOT (
    LOWER(PQ."body") LIKE '%fail%' OR LOWER(PQ."body") LIKE '%problem%' OR LOWER(PQ."body") LIKE '%error%'
    OR LOWER(PQ."body") LIKE '%wrong%' OR LOWER(PQ."body") LIKE '%fix%' OR LOWER(PQ."body") LIKE '%bug%'
    OR LOWER(PQ."body") LIKE '%issue%' OR LOWER(PQ."body") LIKE '%solve%' OR LOWER(PQ."body") LIKE '%trouble%'
  )
),
ranked AS (
  SELECT T."tag_name" AS tag, Q."id" AS question_id, Q."title" AS title, Q."view_count" AS view_count, Q."tags" AS tags,
    Q."creation_date" AS creation_date,
    ROW_NUMBER() OVER (PARTITION BY T."id" ORDER BY Q."view_count" DESC, Q."id") AS rnk,
    COUNT(*) OVER (PARTITION BY T."id") AS tot
  FROM STACKOVERFLOW.STACKOVERFLOW.TAGS T
  JOIN tags_to_use TTU ON T."tag_name"=TTU.tag
  JOIN android_how_to_questions Q ON CONTAINS('|'||Q."tags"||'|', '|'||T."tag_name"||'|')
)
SELECT tag, question_id, title, view_count, tags FROM ranked WHERE rnk<=50 AND tot>=50
