#!/usr/bin/env bash
# MemPalace SessionStart (matcher: compact) hook (Linux/GHA)
# stdout is injected into Claude post-compact context
set +e
STDIN=$(cat)
SESSION_ID=$(echo "$STDIN" | jq -r '.session_id // empty' 2>/dev/null)

# Emit L0+L1 to stdout — Claude reads as post-compaction context
python -m mempalace wake-up --layers 0,1 --format markdown 2>/dev/null || echo "[mempalace] wake-up unavailable"

CFG="$HOME/.everest/fork-heartbeat.json"
if [ -f "$CFG" ]; then
  URL=$(jq -r '.url' "$CFG")
  TOKEN=$(jq -r '.token' "$CFG")
  REPO=$(jq -r '.repo' "$CFG")
  HOST=$(hostname)
  WING="${EVEREST_ACTIVE_WING:-EverestCapital}"
  BODY=$(jq -nc --arg t "$TOKEN" --arg r "$REPO" --arg s "$SESSION_ID" --arg w "$WING" --arg h "$HOST" \
    '{token:$t, repo:$r, event_type:"session_start", session_id:$s, wing:$w, payload:{host:$h, matcher:"compact", source:"claude_code_real"}}')
  curl -sS -X POST "$URL" -H "Content-Type: application/json" -d "$BODY" >/dev/null 2>&1
fi
