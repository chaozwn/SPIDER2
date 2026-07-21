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
ids=[2394935,6014028,11723881,4038479,2868047,27203817]
sql=f'''
SELECT "id",
  LOWER("title") LIKE '%how%' AS title_sub,
  LOWER("body") LIKE '%how%' AS body_sub,
  REGEXP_LIKE("title", '.*\\\\bhow\\\\b.*', 'i') AS title_word,
  REGEXP_LIKE("body", '.*\\\\bhow\\\\b.*', 'i') AS body_word,
  REGEXP_LIKE(LOWER("title"), '.*(^|[^a-z])how([^a-z]|$).*') AS title_manual,
  REGEXP_LIKE(LOWER("body"), '.*(^|[^a-z])how([^a-z]|$).*') AS body_manual,
  LEFT("title", 80) AS title
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE "id" IN ({",".join(map(str,ids))})
'''
cur.execute(sql)
df=pd.DataFrame(cur.fetchall(), columns=[d[0].lower() for d in cur.description])
print(df.to_string(index=False))
# also check one onlyB id to see it has word how
cur.execute('''
SELECT "id",
  REGEXP_LIKE("title", '.*\\\\bhow\\\\b.*', 'i') AS title_word,
  REGEXP_LIKE("body", '.*\\\\bhow\\\\b.*', 'i') AS body_word,
  LEFT("title", 80) AS title
FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS WHERE "id"=11234375
''')
print(pd.DataFrame(cur.fetchall(), columns=[d[0].lower() for d in cur.description]).to_string(index=False))
cur.close(); conn.close()
