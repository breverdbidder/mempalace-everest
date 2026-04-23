# MemPalace PreCompact hook (Win10) — heartbeat via edge function
$ErrorActionPreference = "Continue"
try { python -m mempalace wake-up --layers 0,1 | Out-Host; Write-Host "[mempalace] precompact-hook OK" } catch { Write-Host "[mempalace] precompact-hook ERROR: $_" }

$cfg = Join-Path $env:USERPROFILE ".everestork-heartbeat.json"
if (Test-Path $cfg) {
  $c = Get-Content $cfg | ConvertFrom-Json
  $body = @{ token=$c.token; repo=$c.repo; event_type="precompact_hook"; session_id=[guid]::NewGuid().ToString(); wing=$env:EVEREST_ACTIVE_WING; payload=@{host=$env:COMPUTERNAME} } | ConvertTo-Json -Compress
  Start-Job -ScriptBlock { param($u,$b) try { Invoke-RestMethod -Method Post -Uri $u -Headers @{"Content-Type"="application/json"} -Body $b -TimeoutSec 5 | Out-Null } catch {} } -ArgumentList $c.url, $body | Out-Null
}
