# Build dist\MinerVGA.exe from port\MINERVGA.BAS with QB64 Phoenix Edition.
#   .\build.ps1                       uses C:\Users\<you>\Tools\qb64pe\qb64pe.exe or $env:QB64PE
#   .\build.ps1 -Qb64 D:\qb64pe\qb64pe.exe
param([string]$Qb64 = $(if ($env:QB64PE) { $env:QB64PE } else { Join-Path $HOME 'Tools\qb64pe\qb64pe.exe' }))
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$dist = Join-Path $root 'dist'
if (-not (Test-Path $Qb64)) { throw "QB64-PE not found at $Qb64 (pass -Qb64 or set QB64PE)" }
New-Item -ItemType Directory -Force $dist | Out-Null

# QB64-PE resolves $INCLUDE relative to the source, and writes the EXE where -o says.
& $Qb64 -x (Join-Path $root 'port\MINERVGA.BAS') -o (Join-Path $dist 'MinerVGA.exe') |
    Where-Object { $_ -notmatch '^\[' }
if ($LASTEXITCODE -ne 0 -or -not (Test-Path (Join-Path $dist 'MinerVGA.exe'))) { throw 'Build failed' }

# Data files the game reads next to the EXE. Save and high-score files are only seeded
# from the original release when missing, so rebuilding never wipes a player's progress.
foreach ($f in 'MINERVGA.LBR', 'MINERVGA.DOC') {
    Copy-Item (Join-Path $root $f) $dist -Force
}
foreach ($f in 'MINERVGA.SAV', 'MINERVGA.SCR') {
    if (-not (Test-Path (Join-Path $dist $f))) { Copy-Item (Join-Path $root $f) $dist }
}
Write-Host "Built $(Join-Path $dist 'MinerVGA.exe')  (run with /classic for the original 640x480 layout)"
