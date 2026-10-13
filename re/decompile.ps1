# Rebuild the MinerVGA analysis artifacts from the shipped EXE.
#   1. strip the EXEPACK layer          -> re/out/MINERVGA.unpacked.exe
#   2. restore x87 opcodes in user code -> re/out/MINERVGA.x87.exe
#   3. Ghidra headless decompile        -> re/out/MINERVGA.x87.exe.c
#   4. DGROUP dump (strings/constants)  -> re/out/dgroup.txt
# Needs Python, Ghidra (GHIDRA_INSTALL_DIR) and a JDK 21. Takes ~10 minutes.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$re = $PSScriptRoot
$out = Join-Path $re 'out'
New-Item -ItemType Directory -Force $out | Out-Null

$ghidra = if ($env:GHIDRA_INSTALL_DIR) { $env:GHIDRA_INSTALL_DIR } else {
    [Environment]::GetEnvironmentVariable('GHIDRA_INSTALL_DIR', 'User') }
if (-not $ghidra) { throw 'Set GHIDRA_INSTALL_DIR' }

python -I "$re\tools\unexepack.py" "$root\MINERVGA.EXE" "$out\MINERVGA.unpacked.exe"
# User code is image 0x0000-0x9420 (Ghidra segments 1000 and 1846).
python -I "$re\tools\unemu87.py" "$out\MINERVGA.unpacked.exe" "$out\MINERVGA.x87.exe" 0 9420
python -I "$re\tools\dumpds.py" "$out\MINERVGA.x87.exe" > "$out\dgroup.txt"

$proj = Join-Path $env:TEMP "minervga-ghidra-$PID"
New-Item -ItemType Directory -Force $proj | Out-Null
try {
    & "$ghidra\support\analyzeHeadless.bat" $proj miner -import "$out\MINERVGA.x87.exe" `
        -scriptPath "$re\ghidra" -postScript ExportDecompilation.java $out -deleteProject *> "$out\ghidra.log"
} finally {
    Remove-Item -Recurse -Force $proj -ErrorAction SilentlyContinue
}
Get-Content "$out\ghidra.log" | Select-String 'ExportDecompilation:'
