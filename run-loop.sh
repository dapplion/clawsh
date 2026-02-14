#!/usr/bin/env bash
set -uo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/.env"

# Load Rust/cargo if available
source "$HOME/.cargo/env" 2>/dev/null

export CLAUDE_CODE_OAUTH_TOKEN

WORKDIR="${CLAWSH_WORKDIR:-$DIR/repo}"
LOG_DIR="$DIR/logs"
PROMPT_FILE="${CLAWSH_PROMPT_FILE:-$DIR/prompt.md}"
MAX_FAILURES="${CLAWSH_MAX_FAILURES:-3}"

mkdir -p "$LOG_DIR"
cd "$WORKDIR"

if [ ! -f "$PROMPT_FILE" ]; then
  echo "Error: prompt file not found at $PROMPT_FILE" >&2
  exit 1
fi

PROMPT=$(cat "$PROMPT_FILE")

# Preflight: test claude + telegram comms
echo "=== Preflight: testing claude and telegram ==="
claude -p "Run these two commands in order:
1. ${DIR}/tg-send.sh \"Hello I'm starting a clawsh loop\"
2. ${DIR}/tg-wait.sh \"Give me the ok to start?\"
Print the reply you get and then you're done." \
  --dangerously-skip-permissions \
  --output-format text \
  --max-turns 10 \
  2>&1

if [ $? -ne 0 ]; then
  echo "Preflight failed. Exiting."
  exit 1
fi
echo "=== Preflight passed. Starting loop. ==="

run=0
failures=0
while true; do
  run=$((run + 1))
  timestamp=$(date +%Y%m%d-%H%M%S)
  logfile="$LOG_DIR/run-${run}-${timestamp}.log"

  echo "=== Run $run starting at $timestamp ==="

  claude -p "$PROMPT" \
    --dangerously-skip-permissions \
    --output-format text \
    --verbose \
    --continue \
    2>&1 | tee "$logfile"

  exit_code=$?
  echo "=== Run $run finished with exit code $exit_code ==="

  if [ $exit_code -ne 0 ]; then
    failures=$((failures + 1))
    "$DIR/tg-send.sh" "⚠️ Run $run failed (exit $exit_code). Failure $failures/$MAX_FAILURES."
    if [ $failures -ge "$MAX_FAILURES" ]; then
      "$DIR/tg-send.sh" "🛑 $MAX_FAILURES consecutive failures. Loop stopped."
      exit 1
    fi
    sleep 10
  else
    failures=0
  fi
done
