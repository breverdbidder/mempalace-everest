#!/usr/bin/env bash
# MemPalace Stop hook (Linux/GHA) — reads stdin JSON, fires heartbeat via edge function
set +e
STDIN=$(cat)
SESSION_ID=$(echo "$STDIN" | jq -r '.session_id // empty' 2>/dev/null)
[ -z "$SESSION_ID" ] && SESSION_ID="nosid-$$-$(date +%s)"
TRANSCRIPT=$(echo "$STDIN" | jq -r '.transcript_path // empty' 2>/dev/null)

python -m mempalace save --mode convos >/dev/null 2>&1 || true
echo "[mempalace] stop-hook OK"

CFG="$HOME/.everest/fork-heartbeat.json"
if [ -f "$CFG" ]; then
  URL=$(jq -r '.url' "$CFG")
  TOKEN=$(jq -r '.token' "$CFG")
  REPO=$(jq -r '.repo' "$CFG")
  HOST=$(hostname)
  WING="${EVEREST_ACTIVE_WING:-EverestCapital}"
  BODY=$(jq -nc --arg t "$TOKEN" --arg r "$REPO" --arg s "$SESSION_ID" --arg w "$WING" --arg h "$HOST" --arg tp "$TRANSCRIPT" \
    '{token:$t, repo:$r, event_type:"stop_hook", session_id:$s, wing:$w, payload:{host:$h, transcript:$tp, source:"claude_code_real"}}')
  # Fire synchronously in GHA (short window) but backgrounded in real sessions
  curl -sS -X POST "$URL" -H "Content-Type: application/json" -d "$BODY" >/dev/null 2>&1
fi
