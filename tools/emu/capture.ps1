<#
.SYNOPSIS
Run the original MINERVGA.EXE in DOSBox-X and capture reference screenshots.

.DESCRIPTION
Copies the five original files (and optionally a replacement save file) into a fresh
output folder, so the shipped MINERVGA.SAV/.SCR are never written, boots DOSBox-X straight
into the game and drives it from the keyboard. Each step is one of:
  key <name> [<name>...]   press keys by name: a-z, 0-9, space, enter, esc, up, down, left, right
  text <characters>        type letters, digits and spaces
  wait <seconds>           let the emulated machine catch up
  shot <name>              save the 640x480 DOSBox-X client area as <name>.png
Keys are sent with SendInput as scan codes, so the DOSBox-X window must keep the focus.
Adapted from the After Dark rebuild's tools/emu/capture.ps1.

.EXAMPLE
pwsh tools/emu/capture.ps1 -Name start -Steps "wait 8","shot title","key space","wait 2","shot help"
#>
param(
    [string]$DosboxX = "C:\DOSBox-X\dosbox-x.exe",
    [int]$Cycles = 20000,
    [string]$Save,
    [string]$Time,
    [string[]]$Steps = @(),
    [string]$Name = "capture",
    [string]$OutDir
)

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = (Resolve-Path (Join-Path $here "..\..")).Path
if (-not $OutDir) { $OutDir = Join-Path $root "re\captures\$Name-$(Get-Date -Format yyyyMMdd-HHmmss)" }
$game = Join-Path $OutDir "c"
New-Item -ItemType Directory -Force $game | Out-Null
$OutDir = (Resolve-Path $OutDir).Path
foreach ($f in "MINERVGA.EXE", "MINERVGA.LBR", "MINERVGA.SAV", "MINERVGA.SCR", "MINERVGA.DOC") {
    Copy-Item (Join-Path $root $f) $game -Force
}
if ($Save) { Copy-Item $Save (Join-Path $game "MINERVGA.SAV") -Force }

Add-Type @"
using System; using System.Runtime.InteropServices;
public static class MvWin {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, IntPtr pid);
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint from, uint to, bool attach);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
    [StructLayout(LayoutKind.Sequential)] struct MOUSEINPUT { public int dx, dy; public uint data, flags, time; public IntPtr extra; }
    [StructLayout(LayoutKind.Sequential)] struct KEYBDINPUT { public ushort vk, scan; public uint flags, time; public IntPtr extra; }
    [StructLayout(LayoutKind.Explicit)] struct INPUTUNION { [FieldOffset(0)] public MOUSEINPUT mi; [FieldOffset(0)] public KEYBDINPUT ki; }
    [StructLayout(LayoutKind.Sequential)] struct INPUT { public uint type; public INPUTUNION u; }
    [DllImport("user32.dll", SetLastError = true)] static extern uint SendInput(uint n, INPUT[] inputs, int size);
    public static bool Focus(IntPtr h) {
        IntPtr fg = GetForegroundWindow();
        if (fg == h) return true;
        uint me = GetCurrentThreadId(), other = GetWindowThreadProcessId(fg, IntPtr.Zero);
        AttachThreadInput(me, other, true);
        BringWindowToTop(h);
        SetForegroundWindow(h);
        AttachThreadInput(me, other, false);
        return GetForegroundWindow() == h;
    }
    public static void Key(ushort scan, bool extended, bool up) {
        var i = new INPUT[1];
        i[0].type = 1;
        i[0].u.ki.scan = scan;
        i[0].u.ki.flags = 0x0008u | (extended ? 0x0001u : 0u) | (up ? 0x0002u : 0u);
        if (SendInput(1, i, Marshal.SizeOf(typeof(INPUT))) != 1)
            throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
    }
}
"@

$scanCodes = @{ esc = 0x01; enter = 0x1C; space = 0x39; backspace = 0x0E
    up = "e48"; down = "e50"; left = "e4B"; right = "e4D" }
$row = @{ "1234567890" = 0x02; "qwertyuiop" = 0x10; "asdfghjkl" = 0x1E; "zxcvbnm" = 0x2C }
foreach ($keys in $row.Keys) {
    for ($i = 0; $i -lt $keys.Length; $i++) { $scanCodes["$($keys[$i])"] = $row[$keys] + $i }
}

function Send-Key([IntPtr]$window, [string]$name) {
    $c = $scanCodes[$name.ToLower()]
    if ($null -eq $c) { throw "Unknown key '$name'." }
    $ext = $c -is [string]
    $scan = if ($ext) { [Convert]::ToUInt16($c.Substring(1), 16) } else { [uint16]$c }
    if (-not [MvWin]::Focus($window)) { throw "The DOSBox-X window lost the focus; stopping before '$name'." }
    [MvWin]::Key($scan, $ext, $false); Start-Sleep -Milliseconds 60
    [MvWin]::Key($scan, $ext, $true); Start-Sleep -Milliseconds 90
}

function Get-ClientArea([System.Diagnostics.Process]$p) {
    $p.Refresh()
    $h = $p.MainWindowHandle
    if ($h -eq [IntPtr]::Zero) { return $null }
    $r = New-Object MvWin+RECT; [MvWin]::GetClientRect($h, [ref]$r) | Out-Null
    $pt = New-Object MvWin+POINT; [MvWin]::ClientToScreen($h, [ref]$pt) | Out-Null
    [pscustomobject]@{ Handle = $h; X = $pt.X; Y = $pt.Y; W = $r.Right - $r.Left; H = $r.Bottom - $r.Top }
}

function Save-Still($area, [string]$path) {
    & ffmpeg -loglevel error -y -f gdigrab -draw_mouse 0 -offset_x $area.X -offset_y $area.Y `
        -video_size "$($area.W)x$($area.H)" -i desktop -frames:v 1 $path
}

$timeCmd = if ($Time) { "time $Time" } else { "" }
$conf = Join-Path $OutDir "minervga.conf"
@"
[sdl]
output            = surface
windowresolution  = original
autolock          = false
showmenu          = false
[dosbox]
title             = MVREF
machine           = svga_s3
memsize           = 16
quit warning      = false
[render]
aspect            = false
doublescan        = false
scaler            = none
[cpu]
core              = normal
cputype           = 386
cycles            = fixed $Cycles
[autoexec]
mount c "$game"
c:
$timeCmd
MINERVGA.EXE
exit
"@ | Set-Content -Encoding ascii $conf

$dosbox = Start-Process -FilePath $DosboxX -ArgumentList @("-nopromptfolder", "-conf", "`"$conf`"") -PassThru
try {
    $area = $null
    for ($i = 0; $i -lt 50 -and -not $area; $i++) { Start-Sleep -Milliseconds 200; $area = Get-ClientArea $dosbox }
    if (-not $area) { throw "DOSBox-X window not found." }
    foreach ($step in $Steps) {
        $verb, $rest = $step.Trim().Split(' ', 2)
        switch ($verb) {
            "key" { foreach ($k in $rest.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)) { Send-Key $area.Handle $k } }
            "text" { foreach ($ch in $rest.ToCharArray()) { Send-Key $area.Handle ($(if ($ch -eq ' ') { 'space' } else { "$ch" })) } }
            "wait" { Start-Sleep -Milliseconds ([int]([double]$rest * 1000)) }
            "shot" { Save-Still (Get-ClientArea $dosbox) (Join-Path $OutDir "$rest.png") }
            default { throw "Unknown step '$step'." }
        }
        if ($dosbox.HasExited) { Write-Output "DOSBox-X exited after: $step"; break }
    }
    @{ cycles = $Cycles; save = $Save; time = $Time; steps = $Steps } | ConvertTo-Json |
        Set-Content -Encoding utf8 (Join-Path $OutDir "capture.json")
    Write-Output "Capture written to $OutDir"
}
finally {
    if ($dosbox -and -not $dosbox.HasExited) { Stop-Process -Id $dosbox.Id -Force }
}
