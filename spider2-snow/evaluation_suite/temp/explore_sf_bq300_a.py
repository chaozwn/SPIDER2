#!/usr/bin/env python3
"""Explore filter variants that could produce MAX_ANSWERS=26 for sf_bq300_a."""
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
    "tag_python-2.x_exact_no_py3_tag": '''
SELECT MAX(q."answer_count") AS MAX_ANSWERS
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE CONTAINS('|' || q."tags" || '|', '|python-2.x|')
  AND NOT CONTAINS('|' || q."tags" || '|', '|python-3.x|')
''',
    "tag_python-2.x_exact_exclude_py3_anywhere_tags": '''
SELECT MAX(q."answer_count") AS MAX_ANSWERS
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE CONTAINS('|' || q."tags" || '|', '|python-2.x|')
  AND q."tags" NOT ILIKE '%python-3%'
''',
    "tag_python-2.x_and_not_python_tag": '''
SELECT MAX(q."answer_count") AS MAX_ANSWERS
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE CONTAINS('|' || q."tags" || '|', '|python-2.x|')
  AND NOT CONTAINS('|' || q."tags" || '|', '|python|')
  AND q."tags" NOT ILIKE '%python-3%'
''',
    "tag_like_python-2_exclude_py3_title_only": '''
SELECT MAX(q."answer_count") AS MAX_ANSWERS
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE LOWER(q."tags") LIKE '%python-2%'
  AND LOWER(q."title") NOT LIKE '%python 3%'
  AND LOWER(q."title") NOT LIKE '%python3%'
''',
    "official_plus_exclude_py3_tags": '''
SELECT MAX(q."answer_count") AS MAX_ANSWERS
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE (
    LOWER(q."tags") LIKE '%python-2%'
    OR LOWER(q."title") LIKE '%python 2%'
    OR LOWER(q."body") LIKE '%python 2%'
    OR LOWER(q."title") LIKE '%python2%'
    OR LOWER(q."body") LIKE '%python2%'
  )
  AND LOWER(q."title") NOT LIKE '%python 3%'
  AND LOWER(q."body") NOT LIKE '%python 3%'
  AND LOWER(q."title") NOT LIKE '%python3%'
  AND LOWER(q."body") NOT LIKE '%python3%'
  AND LOWER(q."tags") NOT LIKE '%python-3%'
''',
    "python2_in_title_or_tags_no_body_scan": '''
SELECT MAX(q."answer_count") AS MAX_ANSWERS
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE (
    LOWER(q."tags") LIKE '%python-2%'
    OR LOWER(q."title") LIKE '%python 2%'
    OR LOWER(q."title") LIKE '%python2%'
  )
  AND LOWER(q."title") NOT LIKE '%python 3%'
  AND LOWER(q."title") NOT LIKE '%python3%'
  AND LOWER(q."body") NOT LIKE '%python 3%'
  AND LOWER(q."body") NOT LIKE '%python3%'
''',
    "must_have_python-2_tag_and_official_exclude": '''
SELECT MAX(q."answer_count") AS MAX_ANSWERS
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE LOWER(q."tags") LIKE '%python-2%'
  AND LOWER(q."title") NOT LIKE '%python 3%'
  AND LOWER(q."body") NOT LIKE '%python 3%'
  AND LOWER(q."title") NOT LIKE '%python3%'
  AND LOWER(q."body") NOT LIKE '%python3%'
  AND LOWER(q."tags") NOT LIKE '%python-3%'
''',
    "python_tag_plus_python2_mention_exclude_py3": '''
SELECT MAX(q."answer_count") AS MAX_ANSWERS
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE CONTAINS('|' || q."tags" || '|', '|python|')
  AND (
    LOWER(q."title") LIKE '%python 2%'
    OR LOWER(q."body") LIKE '%python 2%'
    OR LOWER(q."title") LIKE '%python2%'
    OR LOWER(q."body") LIKE '%python2%'
    OR LOWER(q."tags") LIKE '%python-2%'
  )
  AND LOWER(q."title") NOT LIKE '%python 3%'
  AND LOWER(q."body") NOT LIKE '%python 3%'
  AND LOWER(q."title") NOT LIKE '%python3%'
  AND LOWER(q."body") NOT LIKE '%python3%'
''',
    "top10_official_filter_by_answer_count": '''
SELECT q."id", q."answer_count", q."tags", LEFT(q."title", 80) AS title
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q
WHERE (
    LOWER(q."tags") LIKE '%python-2%'
    OR LOWER(q."title") LIKE '%python 2%'
    OR LOWER(q."body") LIKE '%python 2%'
    OR LOWER(q."title") LIKE '%python2%'
    OR LOWER(q."body") LIKE '%python2%'
  )
  AND LOWER(q."title") NOT LIKE '%python 3%'
  AND LOWER(q."body") NOT LIKE '%python 3%'
  AND LOWER(q."title") NOT LIKE '%python3%'
  AND LOWER(q."body") NOT LIKE '%python3%'
ORDER BY q."answer_count" DESC NULLS LAST
LIMIT 15
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
                if "MAX_ANSWERS" in df.columns or df.shape[1] == 1:
                    val = int(df.iloc[0, 0])
                    print(f"-> {val} | match26={val==26} match43={val==43}")
            except Exception as e:
                print("FAILED", e)
            print(f"elapsed={time.time()-t0:.1f}s")
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
