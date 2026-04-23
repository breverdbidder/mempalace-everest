# MemPalace Stop hook (Win10) — reads stdin JSON from Claude Code, preserves real session_id
$ErrorActionPreference = "Continue"
$env:MEMPALACE_HOOK_SOURCE = "claude-code-stop"

# Parse stdin JSON from Claude Code (contains session_id, transcript_path, cwd, hook_event_name)
$stdin = [Console]::In.ReadToEnd()
$real_session_id = $null; $transcript_path = $null
try { $h = $stdin | ConvertFrom-Json; $real_session_id = $h.session_id; $transcript_path = $h.transcript_path } catch {}
if (-not $real_session_id) { $real_session_id = [guid]::NewGuid().ToString() }

try { python -m mempalace save --mode convos 2>&1 | Out-Null; Write-Host "[mempalace] stop-hook OK" } catch { Write-Host "[mempalace] stop-hook ERROR: $_" }

$cfg = Join-Path $env:USERPROFILE ".everest\fork-heartbeat.json"
if (Test-Path $cfg) {
  $c = Get-Content $cfg | ConvertFrom-Json
  $body = @{ token=$c.token; repo=$c.repo; event_type="stop_hook"; session_id=$real_session_id; wing=$env:EVEREST_ACTIVE_WING; payload=@{host=$env:COMPUTERNAME; transcript=$transcript_path; source="claude_code_real"} } | ConvertTo-Json -Compress
  Start-Job -ScriptBlock { param($u,$b) try { Invoke-RestMethod -Method Post -Uri $u -Headers @{"Content-Type"="application/json"} -Body $b -TimeoutSec 5 | Out-Null } catch {} } -ArgumentList $c.url, $body | Out-Null
}
