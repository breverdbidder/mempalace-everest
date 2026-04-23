# MemPalace PreCompact hook (Win10) — real session_id from stdin
$ErrorActionPreference = "Continue"
$stdin = [Console]::In.ReadToEnd()
$real_session_id = $null
try { $h = $stdin | ConvertFrom-Json; $real_session_id = $h.session_id } catch {}
if (-not $real_session_id) { $real_session_id = [guid]::NewGuid().ToString() }

try { python -m mempalace wake-up --layers 0,1 | Out-Host; Write-Host "[mempalace] precompact-hook OK" } catch { Write-Host "[mempalace] precompact-hook ERROR: $_" }

$cfg = Join-Path $env:USERPROFILE ".everest\fork-heartbeat.json"
if (Test-Path $cfg) {
  $c = Get-Content $cfg | ConvertFrom-Json
  $body = @{ token=$c.token; repo=$c.repo; event_type="precompact_hook"; session_id=$real_session_id; wing=$env:EVEREST_ACTIVE_WING; payload=@{host=$env:COMPUTERNAME; source="claude_code_real"} } | ConvertTo-Json -Compress
  Start-Job -ScriptBlock { param($u,$b) try { Invoke-RestMethod -Method Post -Uri $u -Headers @{"Content-Type"="application/json"} -Body $b -TimeoutSec 5 | Out-Null } catch {} } -ArgumentList $c.url, $body | Out-Null
}
