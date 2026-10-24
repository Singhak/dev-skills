# Builds one .skill file per skill into .\dist\ (Windows). Usage: .\package.ps1
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$skills = "dev-core","backend-dev","frontend-dev","fullstack-integration","ship-and-operate","debug-production"
if (Test-Path dist) { Remove-Item dist -Recurse -Force }
New-Item -ItemType Directory dist | Out-Null
foreach ($s in $skills) {
  $desc = (Select-String -Path "$s\SKILL.md" -Pattern '^description: (.*)').Matches[0].Groups[1].Value
  if ($desc.Length -gt 1024) { throw "$s description is $($desc.Length) chars (max 1024)" }
  $tmp = Join-Path $env:TEMP "skillpkg-$s"
  if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
  New-Item -ItemType Directory $tmp | Out-Null
  Copy-Item $s (Join-Path $tmp $s) -Recurse
  $ev = Join-Path $tmp "$s\evals"; if (Test-Path $ev) { Remove-Item $ev -Recurse -Force }
  Compress-Archive -Path (Join-Path $tmp $s) -DestinationPath "dist\$s.zip"
  Move-Item "dist\$s.zip" "dist\$s.skill"
  Remove-Item $tmp -Recurse -Force
  Write-Host "built dist\$s.skill (description: $($desc.Length) chars)"
}
