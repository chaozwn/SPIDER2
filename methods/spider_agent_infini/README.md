# InfiniSynapse

[InfiniSynapse](https://infinisynapse.com) 是一款面向复杂数据分析场景的智能 Agent 平台，专注于让 AI 真正"看懂数据、用好数据"。

## 核心特点

- **自主探查数据**：Agent 可以自行连接数据源，主动浏览数据库 Schema、表结构、字段含义与样本数据，无需人工预先整理元数据或编写数据字典。
- **自助解析与理解**：面对陌生的表和字段，Agent 会自动采样、探索、统计分布，结合上下文推断字段语义，构建对数据的"工作记忆"。
- **端到端任务闭环**：从理解问题、探索数据、生成 SQL/代码、执行验证、到结果归因与可视化，全流程由 Agent 自主完成并可自我纠错。
- **复杂查询能力**：原生支持多表 JOIN、嵌套子查询、窗口函数、跨库分析等复杂 SQL 场景，在 Spider 2.0 等高难度评测中表现优异。
- **多数据源兼容**：支持 Snowflake、BigQuery、PostgreSQL、MySQL 等主流数据仓库与数据库，统一接入、统一推理。
- **可解释与可追溯**：每一步探查、推理和查询都有清晰的执行轨迹，便于人类审计、复用与二次开发。

## 与传统 Text-to-SQL 的区别

传统 Text-to-SQL 依赖预先提供的 Schema 描述与人工标注，难以应对真实企业中字段语义模糊、表关系复杂的场景。
InfiniSynapse 让 Agent "像数据分析师一样"先看数据再写代码——通过主动探索消除信息缺口，从而显著提升复杂业务问题的回答准确率。

## 运行 Spider 2.0 评测

### 1. 准备凭证

将 `infini_credential.json` 与 `snowflake_credential.json` 放在 `methods/spider_agent_infini/` 目录下。

### 2. 注册数据源（setup）

```bash
cd methods/spider_agent_infini

python -m spider_agent_infini.spider_agent_setup_infini

python -m spider_agent_infini.spider_agent_setup_infini --snowflake-only
python -m spider_agent_infini.spider_agent_setup_infini --sqlite-only
python -m spider_agent_infini.spider_agent_setup_infini --types sqlite
python -m spider_agent_infini.spider_agent_setup_infini --types snowflake sqlite
```

该脚本会执行两步初始化（默认两步都跑，可通过 CLI 收窄）：

- `add_database_to_infini()`：依据 `spider2-snow/spider2-snow.jsonl` 中的所有 `db_id`，把 Snowflake 上对应的每个 schema 注册为一个 InfiniSynapse 数据源（命名为 `${db_id}_${schema}`）。
- `add_sqlite_database_to_infini()`：依据 `spider2-lite/resource/databases/spider2-localdb/local-map.jsonl` 中的所有 sqlite `db_id`，把 `spider2-localdb/<db_id>.sqlite` 上传到 InfiniSynapse 并注册为 SQLite 类型数据源（命名为 `db_id` 本身，如 `E_commerce`、`Baseball`）。上传走的是 `sqlite_tmp_<db_id>` 暂存目录，服务端会校验 SQLite 文件头并把它原子地搬到 `<upload_root>/sqlite/<databaseId>/database.sqlite`。

任何单个数据源注册失败都会写入 `setup_failures.log` 并继续处理其余条目。

### 3. 跑 Snowflake 题目

```bash
python run.py --mode csv          # 默认输出 .csv 提交
python run.py --mode sql          # 输出 .sql 提交
python run.py --mode both -j 4    # 同时输出 .sql/.csv，4 并发
```

提交文件会落到 `spider2-snow/evaluation_suite/example_submission_folder[_csv]/`，可直接 `cd spider2-snow/evaluation_suite && python evaluate.py ...` 评测。

### 4. 跑 SQLite (`local*`) 题目

```bash
python run_lite.py --mode csv                # 仅跑 spider2-lite 的 local* 子集
python run_lite.py --instance_id local002    # 调试单条
python run_lite.py --range 1,10 -j 4         # 前 10 条，并发 4
```

`run_lite.py` 与 `run.py` 共用 prompt 骨架/范围解析等公共逻辑，差异点在于：

- 数据源切换调用 `select_databases_by_sqlite_db_id`（按 `name == db_id` 匹配 SQLite 数据源）；
- 数据集来自 `spider2-lite/spider2-lite.jsonl`，且只跑 `instance_id` 以 `local` 开头的题目；
- prompt 里把目标 SQL 方言从 Snowflake 切换为 SQLite（去掉 `database.schema.table` 限定）；
- 提交文件落到 `spider2-lite/evaluation_suite/example_submission_folder[_csv]/`。

## 了解更多

访问官网：<https://infinisynapse.com>
