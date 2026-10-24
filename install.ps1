# Installs the skill pack into a repository on Windows (PowerShell 5.1+ or 7+).
#   Real files:  <repo>\.agents\skills\<skill>\     (Codex, Cursor, Copilot, Antigravity, others)
#   Junction:    <repo>\.claude\skills -> .agents\skills   (Claude Code; junctions need no admin rights)
# Usage (Windows blocks unsigned scripts by default; this bypasses it for this one run only):
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 -Repo C:\path\to\your-repo [-Copy]
# Junction mode is Windows-only; on macOS/Linux PowerShell use -Copy or run install.sh.
param([Parameter(Mandatory=$true)][string]$Repo, [switch]$Copy)
$ErrorActionPreference = "Stop"
$src = $PSScriptRoot
$skills = "dev-core","backend-dev","frontend-dev","fullstack-integration","ship-and-operate","debug-production"
$agents = Join-Path $Repo ".agents\skills"
New-Item -ItemType Directory -Force $agents | Out-Null
foreach ($s in $skills) {
  $dst = Join-Path $agents $s
  if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
  Copy-Item (Join-Path $src $s) $dst -Recurse
}
Write-Host "Installed skills to $agents"

$claudeDir = Join-Path $Repo ".claude"; $claudeSkills = Join-Path $claudeDir "skills"
New-Item -ItemType Directory -Force $claudeDir | Out-Null
$existing = Get-Item $claudeSkills -ErrorAction SilentlyContinue
if ($existing -and -not ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
  foreach ($s in $skills) { $d = Join-Path $claudeSkills $s; if (Test-Path $d) { Remove-Item $d -Recurse -Force }; Copy-Item (Join-Path $src $s) $d -Recurse }
  Write-Host "Existing .claude\skills found: copied skills into it too (keep both in sync when editing)."
} elseif ($Copy) {
  if ($existing) { $existing.Delete() }
  Copy-Item $agents $claudeSkills -Recurse
  Write-Host "Copied skills to $claudeSkills for Claude Code."
} else {
  if ($existing) { $existing.Delete() }
  New-Item -ItemType Junction -Path $claudeSkills -Target $agents | Out-Null
  Write-Host "Created junction $claudeSkills -> $agents for Claude Code."
}

$agentsMd = Join-Path $Repo "AGENTS.md"
$line = 'For every coding task, read `.agents/skills/dev-core/SKILL.md` first and follow its routing table to decide which other skills in `.agents/skills/` to read.'
if (-not ((Test-Path $agentsMd) -and (Select-String -Path $agentsMd -SimpleMatch ".agents/skills/dev-core/SKILL.md" -Quiet))) {
  Add-Content $agentsMd "`n## Skills`n$line"
  Write-Host "Added skills line to $agentsMd"
}
Write-Host "Done. Note: git stores a junction as a plain folder copy on other machines; teammates on macOS/Linux should run install.sh."
