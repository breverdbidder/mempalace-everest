# MemPalace-Everest

Fork of [MemPalace/mempalace](https://github.com/MemPalace/mempalace) (MIT) with DELTA patterns from [mem0ai/mem0](https://github.com/mem0ai/mem0) (Apache-2.0).

## Install (Win10 PowerShell) — one command

```powershell
git clone https://github.com/breverdbidder/mempalace-everest.git
cd mempalace-everest
.\install.ps1
```

`install.ps1` is idempotent and does everything:

1. `pip install -e .` (editable MemPalace)
2. Writes `~/.everest/fork-heartbeat.json` with token and edge-function URL baked in
3. Copies `.claude-plugin/hooks-windows/hooks.json` over `.claude-plugin/hooks/hooks.json` so Win PS hooks take precedence over upstream bash hooks
4. Auto-detects active wing from CWD (`biddeed`, `zonewise`, `property360`, etc.) and sets `EVEREST_ACTIVE_WING`
5. Fires a smoke-test heartbeat and prints `id=N OK` on success

## What the hooks do

Every `Stop` and `PreCompact` event in Claude Code POSTs a heartbeat to the `fork-heartbeat` Supabase edge function. No API keys on the client, no JWT, no env vars — just the token in the config file the installer writes.

## Liveness dashboard

```sql
SELECT * FROM public.v_fork_health_dashboard ORDER BY in_use_score DESC;
```

If MemPalace-Everest drops to `DORMANCY_RISK` a row lands in `watch_health` every 6 hours via `alert_on_fork_dormancy()`.

## Everest additions over upstream

- `.claude-plugin/hooks-windows/` — PowerShell wrappers for Stop + PreCompact with heartbeat
- `mempalace/reranker/` + `mempalace/entity/` — DELTA from mem0 (Apache-2.0 per `NOTICE`)
- `mempalace/reranker_bridge.py` — composition layer (Everest-authored)
- `config/everest-wings.yaml` — 8 tenant wings seeded
- `install.ps1` — one-shot installer
- `CASE-STUDY.md` — adoption value analysis

## Dormancy contract

- `in_use_score >= 7` → alive
- `in_use_score 4-6.99` → stale
- `in_use_score 1-3.99` → dormant
- `in_use_score < 1` → dead
- Scanned daily via `cron.job everest-fork-liveness-daily`
- Alerts fire every 6h via `cron.job everest-fork-dormancy-alert`
