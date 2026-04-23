#!/usr/bin/env bash
# MemPalace PreCompact hook (Linux/GHA)
set +e
STDIN=$(cat)
SESSION_ID=$(echo "$STDIN" | jq -r '.session_id // empty' 2>/dev/null)
[ -z "$SESSION_ID" ] && SESSION_ID="nosid-$$-$(date +%s)"

python -m mempalace wake-up --layers 0,1 2>/dev/null || echo "[mempalace] wake-up unavailable"
echo "[mempalace] precompact-hook OK"

CFG="$HOME/.everest/fork-heartbeat.json"
if [ -f "$CFG" ]; then
  URL=$(jq -r '.url' "$CFG")
  TOKEN=$(jq -r '.token' "$CFG")
  REPO=$(jq -r '.repo' "$CFG")
  HOST=$(hostname)
  WING="${EVEREST_ACTIVE_WING:-EverestCapital}"
  BODY=$(jq -nc --arg t "$TOKEN" --arg r "$REPO" --arg s "$SESSION_ID" --arg w "$WING" --arg h "$HOST" \
    '{token:$t, repo:$r, event_type:"precompact_hook", session_id:$s, wing:$w, payload:{host:$h, source:"claude_code_real"}}')
  curl -sS -X POST "$URL" -H "Content-Type: application/json" -d "$BODY" >/dev/null 2>&1
fi
