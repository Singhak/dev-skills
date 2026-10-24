# Builds one versioned .skill file per skill into .\dist\ (Windows PowerShell 5.1+ or PowerShell 7+).
#
# Windows blocks unsigned scripts by default. Run it with:
#   powershell -ExecutionPolicy Bypass -File .\package.ps1
# (this bypasses the policy for this one run only; it changes no settings)
#
# Zip entries are written with forward slashes so the files unpack correctly on every OS and uploader.
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

$skills = "dev-core","backend-dev","frontend-dev","fullstack-integration","ship-and-operate","debug-production"
$verLine = Select-String -Path "CHANGELOG.md" -Pattern '^## (\d+\.\d+\.\d+)' | Select-Object -First 1
if (-not $verLine) { throw "No version heading like '## 1.0.0' found in CHANGELOG.md" }
$version = $verLine.Matches[0].Groups[1].Value

$dist = Join-Path $PSScriptRoot "dist"
if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
New-Item -ItemType Directory $dist | Out-Null

foreach ($s in $skills) {
  $descMatch = Select-String -Path (Join-Path $s "SKILL.md") -Pattern '^description: (.*)' | Select-Object -First 1
  if (-not $descMatch) { throw "$s/SKILL.md has no description" }
  $desc = $descMatch.Matches[0].Groups[1].Value
  if ($desc.Length -gt 1024) { throw "$s description is $($desc.Length) chars (max 1024)" }
  if ($desc.Contains(": ")) { throw "$s description contains ': ' which breaks unquoted YAML" }

  $out = Join-Path $dist "$s-$version.skill"
  $zip = [System.IO.Compression.ZipFile]::Open($out, [System.IO.Compression.ZipArchiveMode]::Create)
  try {
    $root = (Resolve-Path $s).Path
    Get-ChildItem $root -Recurse -File | Where-Object {
      $_.FullName -notmatch '[\\/]evals[\\/]' -and $_.Name -ne '.DS_Store'
    } | ForEach-Object {
      $rel = $_.FullName.Substring($root.Length).TrimStart('\','/') -replace '\\','/'
      [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, "$s/$rel")
    }
  } finally { $zip.Dispose() }
  Write-Host "built dist/$s-$version.skill (description: $($desc.Length) chars)"
}
