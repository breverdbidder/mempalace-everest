# One-time setup for Everest fork heartbeat environment on Win10
# Run as Ariel (not admin). Persists to user-scope env vars.

[Environment]::SetEnvironmentVariable("SUPABASE_URL", "https://mocerqjnksmhcjzxrewo.supabase.co", "User")
[Environment]::SetEnvironmentVariable("FORK_HEARTBEAT_TOKEN", "90152394abef647c566c1e0d056caeb85964ba5587786fd469264f4b72f1eb8b", "User")

# SUPABASE_ANON_KEY: fetch from Supabase Dashboard > Project Settings > API > anon public key
# Then run:
#   [Environment]::SetEnvironmentVariable("SUPABASE_ANON_KEY", "<paste-here>", "User")

# Active wing (rotates per tenant context):
#   [Environment]::SetEnvironmentVariable("EVEREST_ACTIVE_WING", "BidDeed", "User")

Write-Host "Setup complete. Verify with: `$env:FORK_HEARTBEAT_TOKEN.Substring(0,8)"
Write-Host "Then set SUPABASE_ANON_KEY manually from dashboard (instructions above)."
