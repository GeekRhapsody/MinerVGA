# Zip dist\ into release\MinerVGA-<version>-win64.zip (plus a .sha256 file).
#   .\tools\package.ps1 -Version v1.1.0
# Run build.ps1 first. The zip holds the game, its data files and release\README.txt.
param([Parameter(Mandatory)][string]$Version)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$dist = Join-Path $root 'dist'
$out  = Join-Path $root 'out'
$name = "MinerVGA-$Version-win64"
$stage = Join-Path $out $name

foreach ($f in 'MinerVGA.exe', 'MINERVGA.LBR', 'MINERVGA.DOC', 'MINERVGA.SAV', 'MINERVGA.SCR') {
    if (-not (Test-Path (Join-Path $dist $f))) { throw "dist\$f is missing: run build.ps1 first" }
}
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force $stage | Out-Null
foreach ($f in 'MinerVGA.exe', 'MINERVGA.LBR', 'MINERVGA.DOC', 'MINERVGA.SAV', 'MINERVGA.SCR') {
    Copy-Item (Join-Path $dist $f) $stage
}
Copy-Item (Join-Path $root 'release\README.txt') $stage

$zip = Join-Path $out "$name.zip"
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path $stage -DestinationPath $zip
$hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
Set-Content -Path "$zip.sha256" -Value "$hash  $name.zip" -Encoding ascii
Write-Host "Packaged $zip"
Write-Host "sha256   $hash"
