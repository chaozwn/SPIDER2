#!/usr/bin/env python3
"""More attempts to reproduce MAX_ANSWERS=26; also inspect top matching questions."""
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
    "title_python2_no_body_py3_no_tag_py3": '''
SELECT MAX(q."answer_count") AS MAX_ANSWERS
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE (LOWER(q."title") LIKE '%python 2%' OR LOWER(q."title") LIKE '%python2%' OR LOWER(q."title") LIKE '%python-2%')
  AND LOWER(q."title") NOT LIKE '%python 3%' AND LOWER(q."title") NOT LIKE '%python3%'
  AND LOWER(q."body") NOT LIKE '%python 3%' AND LOWER(q."body") NOT LIKE '%python3%'
  AND LOWER(q."tags") NOT LIKE '%python-3%'
''',
    "official_before_2016": '''
SELECT MAX(q."answer_count") AS MAX_ANSWERS
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE (
    LOWER(q."tags") LIKE '%python-2%'
    OR LOWER(q."title") LIKE '%python 2%' OR LOWER(q."body") LIKE '%python 2%'
    OR LOWER(q."title") LIKE '%python2%' OR LOWER(q."body") LIKE '%python2%'
  )
  AND LOWER(q."title") NOT LIKE '%python 3%' AND LOWER(q."body") NOT LIKE '%python 3%'
  AND LOWER(q."title") NOT LIKE '%python3%' AND LOWER(q."body") NOT LIKE '%python3%'
  AND TO_TIMESTAMP(q."creation_date"/1000000.0) < '2016-01-01'
''',
    "official_before_2018": '''
SELECT MAX(q."answer_count") AS MAX_ANSWERS
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE (
    LOWER(q."tags") LIKE '%python-2%'
    OR LOWER(q."title") LIKE '%python 2%' OR LOWER(q."body") LIKE '%python 2%'
    OR LOWER(q."title") LIKE '%python2%' OR LOWER(q."body") LIKE '%python2%'
  )
  AND LOWER(q."title") NOT LIKE '%python 3%' AND LOWER(q."body") NOT LIKE '%python 3%'
  AND LOWER(q."title") NOT LIKE '%python3%' AND LOWER(q."body") NOT LIKE '%python3%'
  AND TO_TIMESTAMP(q."creation_date"/1000000.0) < '2018-01-01'
''',
    "official_before_2020": '''
SELECT MAX(q."answer_count") AS MAX_ANSWERS
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE (
    LOWER(q."tags") LIKE '%python-2%'
    OR LOWER(q."title") LIKE '%python 2%' OR LOWER(q."body") LIKE '%python 2%'
    OR LOWER(q."title") LIKE '%python2%' OR LOWER(q."body") LIKE '%python2%'
  )
  AND LOWER(q."title") NOT LIKE '%python 3%' AND LOWER(q."body") NOT LIKE '%python 3%'
  AND LOWER(q."title") NOT LIKE '%python3%' AND LOWER(q."body") NOT LIKE '%python3%'
  AND TO_TIMESTAMP(q."creation_date"/1000000.0) < '2020-01-01'
''',
    "answers_with_score_gt0_official": '''
WITH python2_questions AS (
  SELECT q."id" AS question_id
  FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
  WHERE (
      LOWER(q."tags") LIKE '%python-2%'
      OR LOWER(q."title") LIKE '%python 2%' OR LOWER(q."body") LIKE '%python 2%'
      OR LOWER(q."title") LIKE '%python2%' OR LOWER(q."body") LIKE '%python2%'
    )
    AND LOWER(q."title") NOT LIKE '%python 3%' AND LOWER(q."body") NOT LIKE '%python 3%'
    AND LOWER(q."title") NOT LIKE '%python3%' AND LOWER(q."body") NOT LIKE '%python3%'
)
SELECT COUNT(*) AS MAX_ANSWERS
FROM python2_questions q
JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS a
  ON q.question_id = a."parent_id" AND a."score" > 0
GROUP BY q.question_id
ORDER BY MAX_ANSWERS DESC
LIMIT 1
''',
    "inspect_43_question": '''
SELECT q."id", q."answer_count", q."tags", q."title",
       TO_TIMESTAMP(q."creation_date"/1000000.0) AS created,
       (LOWER(q."body") LIKE '%python 3%' OR LOWER(q."body") LIKE '%python3%'
        OR LOWER(q."title") LIKE '%python 3%' OR LOWER(q."title") LIKE '%python3%') AS mentions_py3
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE q."id" = 27835619
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
                if "MAX_ANSWERS" in [c.upper() for c in df.columns]:
                    val = df.iloc[0, 0]
                    if val is not None:
                        val = int(val)
                        print(f"-> match26={val==26} match43={val==43}")
            except Exception as e:
                print("FAILED", e)
            print(f"elapsed={time.time()-t0:.1f}s")
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
