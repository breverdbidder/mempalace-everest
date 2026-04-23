$ErrorActionPreference = "Continue"
try { python -m mempalace wake-up --layers 0,1 | Out-Host; Write-Host "[mempalace] precompact-hook OK" } catch { Write-Host "[mempalace] precompact-hook ERROR: $_" }
