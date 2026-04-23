# MemPalace SessionStart hook (matcher: compact) — the CRITICAL compaction-survival piece
# Runs after Claude Code compacts context. Stdout content is injected into Claude's post-compact context.
$ErrorActionPreference = "Continue"
$stdin = [Console]::In.ReadToEnd()
$real_session_id = $null
try { $h = $stdin | ConvertFrom-Json; $real_session_id = $h.session_id } catch {}

# Emit L0+L1 layers to stdout — Claude reads this as recovered context
try { python -m mempalace wake-up --layers 0,1 --format markdown 2>$null } catch { Write-Host "[mempalace] wake-up failed (install check: pip install -e .)" }

# Heartbeat on the side
$cfg = Join-Path $env:USERPROFILE ".everest\fork-heartbeat.json"
if (Test-Path $cfg) {
  $c = Get-Content $cfg | ConvertFrom-Json
  $body = @{ token=$c.token; repo=$c.repo; event_type="session_start"; session_id=$real_session_id; wing=$env:EVEREST_ACTIVE_WING; payload=@{host=$env:COMPUTERNAME; matcher="compact"; source="claude_code_real"} } | ConvertTo-Json -Compress
  Start-Job -ScriptBlock { param($u,$b) try { Invoke-RestMethod -Method Post -Uri $u -Headers @{"Content-Type"="application/json"} -Body $b -TimeoutSec 5 | Out-Null } catch {} } -ArgumentList $c.url, $body | Out-Null
}
