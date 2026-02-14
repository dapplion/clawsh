#!/usr/bin/env bash
# Send a question to Telegram and block until the user replies
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/.env"

MSG="$*"
[ -z "$MSG" ] && { echo "Usage: tg-wait.sh <question>" >&2; exit 1; }

# Get current latest update_id so we only look for NEW messages
last_update=$(curl -s "https://api.telegram.org/bot${TG_BOT_TOKEN}/getUpdates" \
  | jq "[.result[].update_id] | max // 0")

# Send the question
curl -s "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
  -d chat_id="$TG_CHAT_ID" \
  -d text="🤖 Claude needs input:

$MSG" > /dev/null

# Poll for a new reply (every 15s, timeout after 2 hours)
elapsed=0
while [ $elapsed -lt 7200 ]; do
  reply=$(curl -s "https://api.telegram.org/bot${TG_BOT_TOKEN}/getUpdates?offset=$((last_update + 1))" \
    | jq -r ".result[0].message.text // empty")

  if [ -n "$reply" ]; then
    echo "$reply"
    exit 0
  fi

  sleep 15
  elapsed=$((elapsed + 15))
done

echo "TIMEOUT: No reply received within 2 hours" >&2
exit 1
