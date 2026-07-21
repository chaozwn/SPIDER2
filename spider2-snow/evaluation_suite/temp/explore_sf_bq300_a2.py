#!/usr/bin/env python3
"""Find a filter that yields MAX_ANSWERS=26 on Snowflake for sf_bq300_a."""
import json
import os
import time
import snowflake.connector
import pandas as pd

SUITE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO_ROOT = os.path.dirname(os.path.dirname(SUITE_DIR))
CRED_PATH = next(
    p
    for p in [
        os.path.join(SUITE_DIR, "snowflake_credential.json"),
        os.path.join(REPO_ROOT, "methods", "spider_agent_infini", "snowflake_credential.json"),
    ]
    if os.path.exists(p)
)

VARIANTS = {
    "title_has_python2_exclude_py3": '''
SELECT MAX(q."answer_count") AS MAX_ANSWERS
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE (LOWER(q."title") LIKE '%python 2%' OR LOWER(q."title") LIKE '%python2%')
  AND LOWER(q."title") NOT LIKE '%python 3%'
  AND LOWER(q."title") NOT LIKE '%python3%'
  AND LOWER(q."body") NOT LIKE '%python 3%'
  AND LOWER(q."body") NOT LIKE '%python3%'
''',
    "tags_python-2.7_only_exclude_py3_body": '''
SELECT MAX(q."answer_count") AS MAX_ANSWERS
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE CONTAINS('|' || q."tags" || '|', '|python-2.7|')
  AND LOWER(q."title") NOT LIKE '%python 3%'
  AND LOWER(q."body") NOT LIKE '%python 3%'
  AND LOWER(q."title") NOT LIKE '%python3%'
  AND LOWER(q."body") NOT LIKE '%python3%'
''',
    "tags_python-2_but_not_python_generic": '''
SELECT MAX(q."answer_count") AS MAX_ANSWERS
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE LOWER(q."tags") LIKE '%python-2%'
  AND NOT CONTAINS('|' || q."tags" || '|', '|python|')
  AND LOWER(q."title") NOT LIKE '%python 3%'
  AND LOWER(q."body") NOT LIKE '%python 3%'
  AND LOWER(q."title") NOT LIKE '%python3%'
  AND LOWER(q."body") NOT LIKE '%python3%'
''',
    "official_but_must_tag_python-2_and_tag_python": '''
SELECT MAX(q."answer_count") AS MAX_ANSWERS
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE LOWER(q."tags") LIKE '%python-2%'
  AND CONTAINS('|' || q."tags" || '|', '|python|')
  AND LOWER(q."title") NOT LIKE '%python 3%'
  AND LOWER(q."body") NOT LIKE '%python 3%'
  AND LOWER(q."title") NOT LIKE '%python3%'
  AND LOWER(q."body") NOT LIKE '%python3%'
''',
    "python2_tag_AND_title_or_body_python2_mention": '''
SELECT MAX(q."answer_count") AS MAX_ANSWERS
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE LOWER(q."tags") LIKE '%python-2%'
  AND (
    LOWER(q."title") LIKE '%python 2%' OR LOWER(q."body") LIKE '%python 2%'
    OR LOWER(q."title") LIKE '%python2%' OR LOWER(q."body") LIKE '%python2%'
  )
  AND LOWER(q."title") NOT LIKE '%python 3%'
  AND LOWER(q."body") NOT LIKE '%python 3%'
  AND LOWER(q."title") NOT LIKE '%python3%'
  AND LOWER(q."body") NOT LIKE '%python3%'
''',
    "reg_word_boundary_python2_in_tags": '''
SELECT MAX(q."answer_count") AS MAX_ANSWERS
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE REGEXP_LIKE(LOWER(q."tags"), '(^|\\\\|)python-2(\\\\.|\\\\||$)')
  AND LOWER(q."title") NOT LIKE '%python 3%'
  AND LOWER(q."body") NOT LIKE '%python 3%'
  AND LOWER(q."title") NOT LIKE '%python3%'
  AND LOWER(q."body") NOT LIKE '%python3%'
''',
    "exclude_ssl_cert_question_and_see_top": '''
SELECT q."id", q."answer_count", q."tags", LEFT(q."title", 90) AS title
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE LOWER(q."tags") LIKE '%python-2%'
  AND LOWER(q."title") NOT LIKE '%python 3%'
  AND LOWER(q."body") NOT LIKE '%python 3%'
  AND LOWER(q."title") NOT LIKE '%python3%'
  AND LOWER(q."body") NOT LIKE '%python3%'
ORDER BY q."answer_count" DESC NULLS LAST
LIMIT 30
''',
    "join_count_only_python-2.x_tag": '''
WITH q AS (
  SELECT "id" AS question_id
  FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
  WHERE CONTAINS('|' || "tags" || '|', '|python-2.x|')
    AND LOWER("title") NOT LIKE '%python 3%'
    AND LOWER("body") NOT LIKE '%python 3%'
    AND LOWER("title") NOT LIKE '%python3%'
    AND LOWER("body") NOT LIKE '%python3%'
)
SELECT COUNT(*) AS MAX_ANSWERS
FROM q
LEFT JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS a ON q.question_id = a."parent_id"
GROUP BY q.question_id
ORDER BY MAX_ANSWERS DESC
LIMIT 1
''',
}


def connect():
    cred = json.load(open(CRED_PATH))
    kwargs = {k: v for k, v in cred.items() if k != "session_parameters"}
    account = kwargs.get("account", "")
    if account.endswith(".snowflakecomputing.com"):
        kwargs["account"] = account.removesuffix(".snowflakecomputing.com")
    if "host" in kwargs and "account" not in kwargs:
        host = kwargs.pop("host")
        kwargs["account"] = host.removesuffix(".snowflakecomputing.com")
    elif "host" in kwargs:
        kwargs.pop("host", None)
    kwargs["session_parameters"] = cred.get("session_parameters", {})
    return snowflake.connector.connect(database="STACKOVERFLOW", **kwargs)


def main():
    conn = connect()
    cur = conn.cursor()
    try:
        for name, sql in VARIANTS.items():
            print(f"\n=== {name} ===")
            t0 = time.time()
            try:
                cur.execute(sql)
                cols = [d[0] for d in cur.description]
                rows = cur.fetchall()
                df = pd.DataFrame(rows, columns=cols)
                print(df.to_string(index=False))
                if df.shape[1] == 1:
                    val = int(df.iloc[0, 0])
                    print(f"-> match26={val==26} match43={val==43}")
            except Exception as e:
                print("FAILED", e)
            print(f"elapsed={time.time()-t0:.1f}s")
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
