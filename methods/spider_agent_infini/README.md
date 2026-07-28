# Spider-Agent Infini

[中文](./README.zh-CN.md)

Spider 2.0 evaluation entry point based on [InfiniSynapse](https://infinisynapse.com): submit tasks to the InfiniSynapse Agent, collect `.sql` / `.csv` artifacts, then score them with the official `evaluation_suite`.

## Prerequisites

Configure two credential files in this directory (do not commit them to git):

| File | Purpose |
|------|---------|
| `infini_credential.json` | InfiniSynapse API (`api_key` / `api_url` / `console_url`) |
| `snowflake_credential.json` | Snowflake account (`user` / `password` / `account` / `host`) |

You can also override Infini settings via environment variables: `INFINI_CREDENTIAL_PATH`, `INFINI_API_URL`, `INFINI_CONSOLE_URL`, `INFINI_API_KEY`.

Install dependencies:

```bash
cd methods/spider_agent_infini
pip install -e .
# or: pip install -r requirements.txt
```

## Register / Update Data Sources

Evaluation depends on databases already configured on InfiniSynapse. Register them on first use; afterward, if you only changed `snowflake_credential.json`, refresh credentials without re-registering.

```bash
cd methods/spider_agent_infini

# Update Snowflake credentials (without rebuilding data sources)
python -m spider_agent_infini.spider_agent_setup_infini --update-credentials --remote-only
```

## Run Spider2-Snow (Recommended)

```bash
cd methods/spider_agent_infini

# Read spider2-snow/spider2-snow.jsonl and submit all tasks concurrently (csv by default)
python run.py --mode csv
```

Results land directly in the evaluation directory and can be scored immediately:

| `--mode` | Submission directory |
|----------|----------------------|
| `csv` (default) | `spider2-snow/evaluation_suite/example_submission_folder_csv/` |

Evaluate:

```bash
cd ../../spider2-snow/evaluation_suite
python evaluate.py --result_dir example_submission_folder_csv --mode exec_result
```

## Avoid Leaking Passwords

```bash
cd methods/spider_agent_infini

# Update Snowflake credentials by editing the password in place
python -m spider_agent_infini.spider_agent_setup_infini --update-credentials --remote-only
```

## Learn More

Website: <https://infinisynapse.com>
