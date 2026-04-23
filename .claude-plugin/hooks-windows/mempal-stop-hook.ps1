$ErrorActionPreference = "Continue"
$env:MEMPALACE_HOOK_SOURCE = "claude-code-stop"
try { python -m mempalace save --mode convos 2>&1 | Out-Null; Write-Host "[mempalace] stop-hook OK" } catch { Write-Host "[mempalace] stop-hook ERROR: $_" }
