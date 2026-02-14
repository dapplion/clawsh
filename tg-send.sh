#!/usr/bin/env bash
# Send a Telegram notification (fire-and-forget)
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/.env"

MSG="$*"
[ -z "$MSG" ] && { echo "Usage: tg-send.sh <message>" >&2; exit 1; }

curl -s "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
  -d chat_id="$TG_CHAT_ID" \
  -d text="$MSG" \
  -d parse_mode="Markdown" > /dev/null
