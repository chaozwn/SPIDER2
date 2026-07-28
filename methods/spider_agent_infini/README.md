# Spider-Agent Infini

基于 [InfiniSynapse](https://infinisynapse.com) 的 Spider 2.0 评测入口：把题目提交给 InfiniSynapse Agent，回收 `.sql` / `.csv` 提交物，再交给官方 `evaluation_suite` 打分。

## 前置准备

在本目录配置两份凭证（不要提交到 git）：

| 文件 | 用途 |
|------|------|
| `infini_credential.json` | InfiniSynapse API（`api_key` / `api_url` / `console_url`） |
| `snowflake_credential.json` | Snowflake 账号（`user` / `password` / `account` / `host`） |

也可用环境变量覆盖 Infini 配置：`INFINI_CREDENTIAL_PATH`、`INFINI_API_URL`、`INFINI_CONSOLE_URL`、`INFINI_API_KEY`。

安装依赖：

```bash
cd methods/spider_agent_infini
pip install -e .
# 或：pip install -r requirements.txt
```

## 注册 / 更新数据源

评测依赖 InfiniSynapse 上已配置好的数据库。首次使用需要注册；之后如果只改了 `snowflake_credential.json`，只需刷新凭证，不必重新注册。

```bash
cd methods/spider_agent_infini

# 更新 Snowflake 凭证（不重建数据源）
python -m spider_agent_infini.spider_agent_setup_infini --update-credentials --remote-only
```

## 跑 Spider2-Snow（推荐）

```bash
cd methods/spider_agent_infini

# 读取 spider2-snow/spider2-snow.jsonl，并发提交全部题目（默认 csv）
python run.py --mode csv
```

结果直接落到评测目录，可立刻打分：

| `--mode` | 提交目录 |
|----------|----------|
| `csv`（默认） | `spider2-snow/evaluation_suite/example_submission_folder_csv/` |

评测：

```bash
cd ../../spider2-snow/evaluation_suite
python evaluate.py --result_dir example_submission_folder_csv --mode exec_result
```

## 不想泄露密码

```bash
cd methods/spider_agent_infini

# 更新 Snowflake 凭证 直接修改原来的密码即可
python -m spider_agent_infini.spider_agent_setup_infini --update-credentials --remote-only
```

## 了解更多

官网：<https://infinisynapse.com>
