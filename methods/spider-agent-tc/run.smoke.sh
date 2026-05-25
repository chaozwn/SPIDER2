#!/usr/bin/env bash
# Smoke-test runner for spider-agent-tc on macOS.
# Runs only on smoke.jsonl (2 instances) so you can validate the full pipeline
# (OpenAI -> tool server -> Snowflake) before launching a full 547-task run.

set -euo pipefail

cd "$(dirname "$0")"

# --- Load secrets from .env (OPENAI_API_KEY / OPENAI_API_BASE / MODEL) ---
if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
else
  echo "ERROR: .env not found. Copy .env.example to .env and fill in your keys." >&2
  exit 1
fi

if [[ -z "${OPENAI_API_KEY:-}" || "$OPENAI_API_KEY" == sk-xxxx ]]; then
  echo "ERROR: OPENAI_API_KEY not set in .env" >&2
  exit 1
fi

# --- Verify Snowflake credential is filled ---
CRED=./credentials/snowflake_credential.json
if grep -q "your_username" "$CRED"; then
  echo "ERROR: Fill in $CRED with your Snowflake user/password first." >&2
  exit 1
fi

# --- Paths ---
REPO_ROOT="$(cd ../.. && pwd)"
INPUT_FILE="./smoke.jsonl"
SYSTEM_PROMPT="./prompts/spider_agent.txt"
DATABASES_PATH="$REPO_ROOT/spider2-snow/resource/databases"
DOCUMENTS_PATH="$REPO_ROOT/spider2-snow/resource/documents"

# --- Model / decoding ---
MODEL="${MODEL:-gpt-5.5}"
TEMPERATURE=0.7
TOP_P=0.9
MAX_NEW_TOKENS=12000
MAX_ROUNDS=25
NUM_THREADS=2
ROLLOUT_NUMBER=1
EXPERIMENT_SUFFIX="smoke"

OUTPUT_FOLDER="./results/${MODEL}_temp${TEMPERATURE}_rounds${MAX_ROUNDS}_rollout${ROLLOUT_NUMBER}_${EXPERIMENT_SUFFIX}"
mkdir -p "./results"
echo "Output folder: $OUTPUT_FOLDER"

# --- macOS-friendly host detection (the original run.sh uses linux-only `hostname -I`) ---
host="127.0.0.1"
# Pick a free port in the 30000-31000 range
port=$(python3 - <<'PY'
import socket, random
for _ in range(50):
    p = random.randint(30000, 31000)
    s = socket.socket()
    try:
        s.bind(("127.0.0.1", p)); s.close(); print(p); break
    except OSError:
        continue
PY
)

tool_server_url="http://${host}:${port}/get_observation"

# --- Start the tool server in background ---
python -m servers.serve --workers_per_tool 8 --host "$host" --port "$port" &
server_pid=$!
trap 'echo "Stopping tool server (pid=$server_pid)"; kill $server_pid 2>/dev/null || true' EXIT
echo "Tool server (pid=$server_pid) started at $tool_server_url"

# Wait for server to be ready
for i in {1..20}; do
  if curl -sf "http://${host}:${port}/" >/dev/null 2>&1 \
     || curl -sf "http://${host}:${port}/docs" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

# --- Run agent ---
python agent/main.py \
  --input_file "$INPUT_FILE" \
  --output_folder "$OUTPUT_FOLDER" \
  --system_prompt_path "$SYSTEM_PROMPT" \
  --databases_path "$DATABASES_PATH" \
  --documents_path "$DOCUMENTS_PATH" \
  --model "$MODEL" \
  --temperature "$TEMPERATURE" \
  --top_p "$TOP_P" \
  --max_new_tokens "$MAX_NEW_TOKENS" \
  --api_host "$host" \
  --api_port "$port" \
  --max_rounds "$MAX_ROUNDS" \
  --num_threads "$NUM_THREADS" \
  --rollout_number "$ROLLOUT_NUMBER"

echo
echo "Smoke run finished. Predictions: $OUTPUT_FOLDER"
echo "Convert to submission CSVs:"
echo "  python convert_to_submission_format.py $OUTPUT_FOLDER ../../spider2-snow/evaluation_suite/result_smoke"
