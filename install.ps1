# install.ps1 v3 — merges into ~/.claude/settings.json (user scope, guaranteed pickup) + real headless verification
$ErrorActionPreference = "Stop"
$repoRoot = $PSScriptRoot
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }

Write-Host "`n=== MemPalace-Everest installer v3 ===" -ForegroundColor Cyan

try { $pv = (python --version) 2>&1; Write-Host "  python: $pv" } catch { throw "Python 3 not found in PATH" }

# Resolve repo absolute path with forward slashes (for hook commands)
$repoAbsFwd = ($repoRoot -replace '\\','/')

Write-Host "`n[1/6] pip install -e ." -ForegroundColor Yellow
pip install -e . --quiet
if ($LASTEXITCODE -ne 0) { throw "pip install failed" }

Write-Host "[2/6] writing heartbeat config" -ForegroundColor Yellow
$cfgDir = Join-Path $env:USERPROFILE ".everest"
New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
$cfgPath = Join-Path $cfgDir "fork-heartbeat.json"
@{ url="https://mocerqjnksmhcjzxrewo.supabase.co/functions/v1/fork-heartbeat"; token="90152394abef647c566c1e0d056caeb85964ba5587786fd469264f4b72f1eb8b"; repo="breverdbidder/mempalace-everest" } | ConvertTo-Json | Set-Content -Path $cfgPath -Encoding UTF8
Write-Host "  -> $cfgPath"

Write-Host "[3/6] merging hooks into user-scope ~/.claude/settings.json" -ForegroundColor Yellow
$claudeDir = Join-Path $env:USERPROFILE ".claude"
New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null
$settingsPath = Join-Path $claudeDir "settings.json"
$existing = @{}
if (Test-Path $settingsPath) { try { $existing = Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable } catch { $existing = @{} } }
if (-not $existing.hooks) { $existing.hooks = @{} }

$stopCmd  = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$repoAbsFwd/.claude-plugin/hooks-windows/mempal-stop-hook.ps1`""
$preCmd   = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$repoAbsFwd/.claude-plugin/hooks-windows/mempal-precompact-hook.ps1`""
$startCmd = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$repoAbsFwd/.claude-plugin/hooks-windows/mempal-session-start-compact-hook.ps1`""

$existing.hooks.Stop        = @(@{ hooks = @(@{ type="command"; command=$stopCmd;  async=$true; timeout=10 }) })
$existing.hooks.PreCompact  = @(@{ hooks = @(@{ type="command"; command=$preCmd;   async=$true; timeout=10 }) })
$existing.hooks.SessionStart= @(@{ matcher="compact"; hooks = @(@{ type="command"; command=$startCmd; timeout=10 }) })

$existing | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath -Encoding UTF8
Write-Host "  -> $settingsPath (user-scope, guaranteed global activation)"

Write-Host "[4/6] auto-detecting active wing" -ForegroundColor Yellow
$wingMap = @{ "biddeed"="BidDeed"; "zonewise"="ZoneWise"; "brevard-doors"="BrevardDoors"; "property360"="Property360"; "kenstrekt"="Kenstrekt"; "protection-partners"="ProtectionPartners"; "everest-portfolio"="EverestPortfolio"; "everest-capital"="EverestCapital" }
$cwd = (Get-Location).Path.ToLower(); $wing = "EverestCapital"
foreach ($k in $wingMap.Keys) { if ($cwd -like "*\$k*") { $wing = $wingMap[$k]; break } }
[Environment]::SetEnvironmentVariable("EVEREST_ACTIVE_WING", $wing, "User")
Write-Host "  wing: $wing"

# SMOKE TEST
Write-Host "[5/6] smoke test: direct POST to edge function" -ForegroundColor Yellow
$smokeSid = "install-smoke-" + [guid]::NewGuid().ToString()
$body = @{ token="90152394abef647c566c1e0d056caeb85964ba5587786fd469264f4b72f1eb8b"; repo="breverdbidder/mempalace-everest"; event_type="session_start"; session_id=$smokeSid; wing=$wing; payload=@{host=$env:COMPUTERNAME; installer="install.ps1"; source="installer"} } | ConvertTo-Json -Compress
$smokeOK = $false
try {
  $res = Invoke-RestMethod -Method Post -Uri "https://mocerqjnksmhcjzxrewo.supabase.co/functions/v1/fork-heartbeat" -Headers @{"Content-Type"="application/json"} -Body $body -TimeoutSec 10
  if ($res.ok) { Write-Host "  smoke OK (id=$($res.id))" -ForegroundColor Green; $smokeOK = $true }
} catch { Write-Host "  smoke ERROR: $_" -ForegroundColor Red }

# HEADLESS VERIFICATION — real claude -p run, poll edge function GET for stop_hook from claude_code_real
Write-Host "[6/6] headless verification: claude -p + poll for real Stop hook fire" -ForegroundColor Yellow
$claude = Get-Command claude -ErrorAction SilentlyContinue
$headlessOK = $false
if (-not $claude) {
  Write-Host "  WARN: claude CLI not in PATH — skipped. Run any real session and check dashboard." -ForegroundColor Yellow
} else {
  $beforeIso = (Get-Date).ToUniversalTime().ToString("o")
  Start-Sleep -Milliseconds 500
  try {
    Push-Location $repoRoot
    Write-Host "  running: claude -p 'ping verify-hook-install'"
    $null = claude -p "ping verify-hook-install (install.ps1 verification)" 2>$null
  } finally { Pop-Location }
  $tokQ = [uri]::EscapeDataString("90152394abef647c566c1e0d056caeb85964ba5587786fd469264f4b72f1eb8b")
  $sinceQ = [uri]::EscapeDataString($beforeIso)
  $hostQ  = [uri]::EscapeDataString($env:COMPUTERNAME)
  $pollUrl = "https://mocerqjnksmhcjzxrewo.supabase.co/functions/v1/fork-heartbeat?token=$tokQ&event_type=stop_hook&since=$sinceQ&hostname=$hostQ&source=claude_code_real"
  $deadline = (Get-Date).AddSeconds(25)
  while ((Get-Date) -lt $deadline -and -not $headlessOK) {
    Start-Sleep -Seconds 2
    try {
      $p = Invoke-RestMethod -Method Get -Uri $pollUrl -TimeoutSec 5
      if ($p.ok -and $p.count -gt 0) {
        $headlessOK = $true
        Write-Host "  HEADLESS VERIFIED: stop_hook heartbeat received from real Claude Code session" -ForegroundColor Green
        Write-Host "  event session_id: $($p.events[0].session_id)"
      }
    } catch {}
  }
  if (-not $headlessOK) { Write-Host "  headless verification: TIMEOUT (25s). Hook may not be wired. Check ~/.claude/settings.json" -ForegroundColor Red }
}

# Log installation outcome
$installBody = @{ token="90152394abef647c566c1e0d056caeb85964ba5587786fd469264f4b72f1eb8b"; repo="breverdbidder/mempalace-everest"; event_type="skill_loaded"; session_id="install-log-" + [guid]::NewGuid().ToString(); wing=$wing; payload=@{host=$env:COMPUTERNAME; installer="install.ps1"; smoke_ok=$smokeOK; headless_ok=$headlessOK; install_marker=$true; installer_version="v3"; source="installer"} } | ConvertTo-Json -Compress
try { Invoke-RestMethod -Method Post -Uri "https://mocerqjnksmhcjzxrewo.supabase.co/functions/v1/fork-heartbeat" -Headers @{"Content-Type"="application/json"} -Body $installBody -TimeoutSec 10 | Out-Null } catch {}

Write-Host "`n=== Install complete ===" -ForegroundColor Cyan
Write-Host "  smoke_test_passed: $smokeOK"
Write-Host "  headless_test_passed: $headlessOK"
if ($smokeOK -and $headlessOK) { Write-Host "  VERIFIED end-to-end. Hooks active, heartbeats flowing." -ForegroundColor Green }
elseif ($smokeOK) { Write-Host "  Partial: smoke works, headless did not complete. Any real session will confirm." -ForegroundColor Yellow }
else { Write-Host "  FAIL: smoke test broke. Check ~/.everest/fork-heartbeat.json + edge function URL." -ForegroundColor Red }
Write-Host "`nDashboard:"
Write-Host "  SELECT * FROM public.v_fork_health_dashboard;"
Write-Host "  SELECT * FROM public.v_hook_install_verified WHERE hostname='$env:COMPUTERNAME';`n"
