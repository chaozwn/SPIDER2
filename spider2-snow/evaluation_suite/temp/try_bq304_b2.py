import json, os, snowflake.connector, pandas as pd
SUITE=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROOT=os.path.dirname(os.path.dirname(SUITE))
CRED=next(p for p in [os.path.join(SUITE,"snowflake_credential.json"), os.path.join(ROOT,"methods","spider_agent_infini","snowflake_credential.json")] if os.path.exists(p))
cred=json.load(open(CRED))
kwargs={k:v for k,v in cred.items() if k!="session_parameters"}
acc=kwargs.get("account","")
if acc.endswith(".snowflakecomputing.com"):
    kwargs["account"]=acc.removesuffix(".snowflakecomputing.com")
if "host" in kwargs and "account" not in kwargs:
    kwargs["account"]=kwargs.pop("host").removesuffix(".snowflakecomputing.com")
elif "host" in kwargs:
    kwargs.pop("host", None)
kwargs["session_parameters"]=cred.get("session_parameters",{})
conn=snowflake.connector.connect(database="STACKOVERFLOW", **kwargs)
cur=conn.cursor()
# Check exclusion hits for A-only high-view questions that HAVE word how
sql='''
SELECT "id",
  LEFT("title", 60) AS title,
  (LOWER("title") LIKE '%fail%' OR LOWER("title") LIKE '%problem%' OR LOWER("title") LIKE '%error%'
   OR LOWER("title") LIKE '%wrong%' OR LOWER("title") LIKE '%fix%' OR LOWER("title") LIKE '%bug%'
   OR LOWER("title") LIKE '%issue%' OR LOWER("title") LIKE '%solve%' OR LOWER("title") LIKE '%trouble%') AS title_bad_sub,
  (LOWER("body") LIKE '%fail%' OR LOWER("body") LIKE '%problem%' OR LOWER("body") LIKE '%error%'
   OR LOWER("body") LIKE '%wrong%' OR LOWER("body") LIKE '%fix%' OR LOWER("body") LIKE '%bug%'
   OR LOWER("body") LIKE '%issue%' OR LOWER("body") LIKE '%solve%' OR LOWER("body") LIKE '%trouble%') AS body_bad_sub,
  REGEXP_LIKE(LOWER("body"), '.*(^|[^a-z])(fail|problem|error|wrong|fix|bug|issue|solve|trouble)([^a-z]|$).*') AS body_bad_word,
  REGEXP_LIKE("body", '.*\\bhow\\b.*', 'i') AS body_how_word,
  LOWER("body") LIKE '%how%' AS body_how_sub
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE "id" IN (2394935, 2868047, 4038479, 6014028, 11723881, 27203817)
'''
cur.execute(sql)
print(pd.DataFrame(cur.fetchall(), columns=[d[0].lower() for d in cur.description]).to_string(index=False))

# Try exclusion with word boundaries + how with word boundaries
sql2=open(os.path.join(os.path.dirname(os.path.abspath(__file__)),"sf_bq304_b_try.sql"),encoding="utf-8-sig").read()
# rewrite with word-boundary exclusions too
sql2='''
WITH tags_to_use AS (
  SELECT column1 AS tag, column2 AS idx FROM VALUES
    ('android-layout',0),('android-activity',1),('android-intent',2),('android-edittext',3),
    ('android-fragments',4),('android-recyclerview',5),('listview',6),('android-actionbar',7),
    ('google-maps',8),('android-asynctask',9)
),
android_how_to_questions AS (
  SELECT PQ."id", PQ."title", PQ."tags", PQ."view_count"
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
  AND (REGEXP_LIKE(LOWER(PQ."title")||' '||LOWER(PQ."body"), '.*(^|[^a-z])how([^a-z]|$).*'))
  AND NOT REGEXP_LIKE(LOWER(PQ."title")||' '||LOWER(PQ."body"), '.*(^|[^a-z])(fail|problem|error|wrong|fix|bug|issue|solve|trouble)([^a-z]|$).*')
),
ranked AS (
  SELECT T."tag_name" AS tag, Q."id" AS question_id, Q."title" AS title, Q."view_count" AS view_count, Q."tags" AS tags,
    RANK() OVER (PARTITION BY T."id" ORDER BY Q."view_count" DESC) AS rnk,
    COUNT(*) OVER (PARTITION BY T."id") AS tot
  FROM STACKOVERFLOW.STACKOVERFLOW.TAGS T
  JOIN tags_to_use TTU ON T."tag_name"=TTU.tag
  JOIN android_how_to_questions Q ON CONTAINS('|'||Q."tags"||'|', '|'||T."tag_name"||'|')
)
SELECT tag, question_id, title, view_count, tags FROM ranked WHERE rnk<=50 AND tot>=50
'''
print("exec word how + word exclude...")
cur.execute(sql2)
df=pd.DataFrame(cur.fetchall(), columns=[d[0].lower() for d in cur.description])
gb=pd.read_csv(os.path.join(SUITE,"gold","exec_result","sf_bq304_b.csv"))
pred=set(zip(df["tag"], df["question_id"].astype(int), df["tags"]))
gold=set(zip(gb["tag"], gb["question_id"].astype(int), gb["tags"]))
print("shape", df.shape, "intersect", len(pred&gold), "only_pred", len(pred-gold), "only_gold", len(gold-pred))
cur.close(); conn.close()
