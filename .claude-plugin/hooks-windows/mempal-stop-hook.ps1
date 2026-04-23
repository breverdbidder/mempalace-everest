# MemPalace Stop hook (Win10) — reads config, POSTs via edge function
$ErrorActionPreference = "Continue"
$env:MEMPALACE_HOOK_SOURCE = "claude-code-stop"
try { python -m mempalace save --mode convos 2>&1 | Out-Null; Write-Host "[mempalace] stop-hook OK" } catch { Write-Host "[mempalace] stop-hook ERROR: $_" }

$cfg = Join-Path $env:USERPROFILE ".everestork-heartbeat.json"
if (Test-Path $cfg) {
  $c = Get-Content $cfg | ConvertFrom-Json
  $body = @{ token=$c.token; repo=$c.repo; event_type="stop_hook"; session_id=[guid]::NewGuid().ToString(); wing=$env:EVEREST_ACTIVE_WING; payload=@{host=$env:COMPUTERNAME} } | ConvertTo-Json -Compress
  Start-Job -ScriptBlock { param($u,$b) try { Invoke-RestMethod -Method Post -Uri $u -Headers @{"Content-Type"="application/json"} -Body $b -TimeoutSec 5 | Out-Null } catch {} } -ArgumentList $c.url, $body | Out-Null
}
