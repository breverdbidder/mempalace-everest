# install.ps1 — MemPalace-Everest one-shot installer
# Run from repo root after: git clone ... && cd mempalace-everest
# Idempotent. Re-run any time.

$ErrorActionPreference = "Stop"
$repoRoot = $PSScriptRoot
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }

Write-Host "`n=== MemPalace-Everest installer ===" -ForegroundColor Cyan

try { $pv = (python --version) 2>&1; Write-Host "  python: $pv" } catch { throw "Python 3 not found in PATH" }

Write-Host "`n[1/5] pip install -e ." -ForegroundColor Yellow
pip install -e . --quiet
if ($LASTEXITCODE -ne 0) { throw "pip install failed" }

Write-Host "[2/5] writing heartbeat config" -ForegroundColor Yellow
$cfgDir = Join-Path $env:USERPROFILE ".everest"
New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
$cfgPath = Join-Path $cfgDir "fork-heartbeat.json"
$cfg = @{
  url   = "https://mocerqjnksmhcjzxrewo.supabase.co/functions/v1/fork-heartbeat"
  token = "90152394abef647c566c1e0d056caeb85964ba5587786fd469264f4b72f1eb8b"
  repo  = "breverdbidder/mempalace-everest"
} | ConvertTo-Json
Set-Content -Path $cfgPath -Value $cfg -Encoding UTF8
Write-Host "  -> $cfgPath"

Write-Host "[3/5] wiring Claude Code hooks" -ForegroundColor Yellow
$hooksDir = Join-Path $repoRoot ".claude-pluginhooks"
New-Item -ItemType Directory -Force -Path $hooksDir | Out-Null
Copy-Item "$repoRoot.claude-pluginhooks-windowshooks.json" "$hooksDirhooks.json" -Force
Write-Host "  -> $hooksDirhooks.json"

Write-Host "[4/5] detecting active wing" -ForegroundColor Yellow
$wingMap = @{
  "biddeed"="BidDeed"; "zonewise"="ZoneWise"; "brevard-doors"="BrevardDoors";
  "property360"="Property360"; "kenstrekt"="Kenstrekt"; "protection-partners"="ProtectionPartners";
  "everest-portfolio"="EverestPortfolio"; "everest-capital"="EverestCapital"
}
$cwd = (Get-Location).Path.ToLower()
$wing = "EverestCapital"
foreach ($k in $wingMap.Keys) { if ($cwd -like "*$k*") { $wing = $wingMap[$k]; break } }
[Environment]::SetEnvironmentVariable("EVEREST_ACTIVE_WING", $wing, "User")
Write-Host "  wing: $wing"

Write-Host "[5/5] smoke test: POST to edge function" -ForegroundColor Yellow
$body = @{
  token = (Get-Content $cfgPath | ConvertFrom-Json).token
  repo  = "breverdbidder/mempalace-everest"
  event_type = "session_start"
  session_id = [guid]::NewGuid().ToString()
  wing = $wing
  payload = @{ installer = "install.ps1"; host = $env:COMPUTERNAME }
} | ConvertTo-Json -Compress

try {
  $res = Invoke-RestMethod -Method Post -Uri "https://mocerqjnksmhcjzxrewo.supabase.co/functions/v1/fork-heartbeat" -Headers @{ "Content-Type" = "application/json" } -Body $body -TimeoutSec 10
  if ($res.ok) { Write-Host "  heartbeat OK (id=$($res.id))" -ForegroundColor Green } else { Write-Host "  heartbeat FAIL: $($res | ConvertTo-Json)" -ForegroundColor Red }
} catch { Write-Host "  heartbeat ERROR: $_" -ForegroundColor Red }

Write-Host "`nDONE. Dashboard:" -ForegroundColor Cyan
Write-Host "  SELECT * FROM public.v_fork_health_dashboard ORDER BY in_use_score DESC;`n"
