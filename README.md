```
       __                    __
  ____/ /___ __      _______/ /_
 / __/ / __ `/ | /| / / ___/ __ \
/ /_/ / /_/ /| |/ |/ (__  ) / / /
\___/_/\__,_/ |__/|__/____/_/ /_/

       bash loop + telegram. that's it.
```

Autonomous Claude Code on a VPS. No framework, no dependencies beyond `claude`, `curl`, `jq`.

```
clawsh/
├── run-loop.sh     ← the loop
├── tg-send.sh      ← fire-and-forget telegram notification
├── tg-wait.sh      ← blocking telegram Q&A (2hr timeout)
├── prompt.md       ← the system prompt given to claude each run
├── .env            ← secrets (not committed)
└── repo/           ← your project (git clone it here)
```

## Setup

**1. Clone clawsh and your project**

```bash
git clone git@github.com:dapplion/clawsh.git
cd clawsh
git clone git@github.com:you/your-project.git repo
```

**2. Create a Telegram bot**

- Message [@BotFather](https://t.me/BotFather) → `/newbot` → save the token
- Message your bot, then get your chat ID:
```bash
curl -s "https://api.telegram.org/bot<TOKEN>/getUpdates" | jq '.result[0].message.chat.id'
```

**3. Get a Claude Code token**

```bash
claude setup-token
```

**4. Configure**

```bash
cp env.example .env
# Fill in CLAUDE_CODE_OAUTH_TOKEN, TG_BOT_TOKEN, TG_CHAT_ID
```

**5. Edit the prompt**

Edit `prompt.md` to describe what claude should do in each loop iteration. This is the most important file — it controls everything.

**6. Run**

```bash
chmod +x run-loop.sh tg-send.sh tg-wait.sh
tmux new -s clawsh
./run-loop.sh
# Ctrl+B, D to detach
```

On launch, claude sends you a Telegram message and waits for your "ok" before starting the real loop.

## How it works

```
┌─────────────┐     ┌──────────┐     ┌──────────┐
│  run-loop   │────▶│  claude   │────▶│   repo   │
│   (bash)    │     │   -p ...  │     │  (git)   │
└──────┬──────┘     └────┬─────┘     └──────────┘
       │                 │
       │            ┌────▼─────┐
       │            │ telegram │◀──── you, on your phone
       │            └──────────┘
       │
       ▼
   on failure ×3 → stop + notify
```

Each iteration:
1. `claude -p` reads `prompt.md` and works autonomously
2. `--continue` resumes the previous conversation for context
3. `--dangerously-skip-permissions` — no permission prompts (run as non-root user)
4. On success → loop immediately
5. On failure → retry with 10s cooldown, stop after 3 consecutive failures

## Configuration

| Env var | Description |
|---|---|
| `CLAWSH_WORKDIR` | Project directory (default: `./repo`) |
| `CLAWSH_PROMPT_FILE` | Prompt file path (default: `./prompt.md`) |
| `CLAWSH_MAX_FAILURES` | Consecutive failures before stopping (default: `3`) |

## Notes

- `--dangerously-skip-permissions` requires a non-root user. Create one: `useradd -m -s /bin/bash clawsh`
- The prompt can reference `tg-send.sh` and `tg-wait.sh` by absolute path so claude can message you
- Logs go to `logs/` — one file per run
- Works with any project, any language. Just change the prompt.
