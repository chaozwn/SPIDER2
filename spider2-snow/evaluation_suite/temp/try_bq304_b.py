import json, os, snowflake.connector, pandas as pd
SUITE=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROOT=os.path.dirname(os.path.dirname(SUITE))
CRED=next(p for p in [os.path.join(SUITE,"snowflake_credential.json"), os.path.join(ROOT,"methods","spider_agent_infini","snowflake_credential.json")] if os.path.exists(p))
sql=open(os.path.join(os.path.dirname(os.path.abspath(__file__)),"sf_bq304_b_try.sql"),encoding="utf-8-sig").read()
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
print("exec...")
cur.execute(sql)
df=pd.DataFrame(cur.fetchall(), columns=[d[0].lower() for d in cur.description])
print("shape", df.shape)
gb=pd.read_csv(os.path.join(SUITE,"gold","exec_result","sf_bq304_b.csv"))
pred=set(zip(df["tag"], df["question_id"].astype(int), df["tags"]))
gold=set(zip(gb["tag"], gb["question_id"].astype(int), gb["tags"]))
print("intersect", len(pred&gold), "only_pred", len(pred-gold), "only_gold", len(gold-pred))
if pred!=gold:
    print("sample only_gold", list(gold-pred)[:3])
    print("sample only_pred", list(pred-gold)[:3])
cur.close(); conn.close()
