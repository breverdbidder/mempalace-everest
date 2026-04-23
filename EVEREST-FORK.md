# MemPalace-Everest

Fork of MemPalace/mempalace (MIT) + mem0ai/mem0 DELTA (Apache-2.0).

## Everest additions
- .claude-plugin/hooks-windows/ — PowerShell wrappers for Stop + PreCompact
- mempalace/reranker/, mempalace/entity/ — DELTA from mem0
- mempalace/reranker_bridge.py — composition layer
- config/everest-wings.yaml — 8 tenant wings
- NOTICE — Apache-2.0 attribution

## Install (Win10 PowerShell)
```powershell
git clone https://github.com/breverdbidder/mempalace-everest.git
cd mempalace-everest
pip install -e .
Copy-Item .claude-plugin/hooks-windows/hooks.json .claude-plugin/hooks/hooks.json -Force
```
