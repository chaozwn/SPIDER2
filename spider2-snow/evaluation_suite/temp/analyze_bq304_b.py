import pandas as pd
v=pd.read_csv(r"d:\workspace\SPIDER2\spider2-snow\evaluation_suite\temp\sf_bq304_verified.csv")
b=pd.read_csv(r"d:\workspace\SPIDER2\spider2-snow\evaluation_suite\gold\exec_result\sf_bq304_b.csv")
a=pd.read_csv(r"d:\workspace\SPIDER2\spider2-snow\evaluation_suite\gold\exec_result\sf_bq304_a.csv")
pred=set(zip(v["tag"], v["question_id"].astype(int)))
gold=set(zip(b["tag"], b["question_id"].astype(int)))
print("onlyB", len(gold-pred), "onlyV", len(pred-gold))
for tag in sorted(b["tag"].unique()):
    bv=int(b.loc[b.tag==tag,"view_count"].min())
    vv=int(v.loc[v.tag==tag,"view_count"].min())
    print(tag, "Bmin", bv, "Vmin", vv, "Bmax", int(b.loc[b.tag==tag,"view_count"].max()), "Vmax", int(v.loc[v.tag==tag,"view_count"].max()))
onlyB_df=b.merge(v[["tag","question_id"]], on=["tag","question_id"], how="left", indicator=True)
onlyB_df=onlyB_df[onlyB_df["_merge"]=="left_only"][["tag","question_id","title","view_count","tags"]]
print(onlyB_df.head(15).to_string(index=False))
onlyV_df=v.merge(b[["tag","question_id"]], on=["tag","question_id"], how="left", indicator=True)
onlyV_df=onlyV_df[onlyV_df["_merge"]=="left_only"][["tag","question_id","title","view_count","tags"]]
print("--- onlyV ---")
print(onlyV_df.head(15).to_string(index=False))
