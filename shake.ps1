$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json
$app = $p.App
$power = [int]$p.Power
$time = [int]$p.Time

if ($app -eq "mouse") {
    $code = @'
using System;
using System.Runtime.InteropServices;
public class M {
    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out P p);
    public struct P { public int X, Y; }
}
'@
    Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
    $point = New-Object M+P
    [M]::GetCursorPos([ref]$point)
    $originX = $point.X
    $originY = $point.Y
    $end = (Get-Date).AddSeconds($time)
    $rng = New-Object System.Random
    while ((Get-Date) -lt $end) {
        $dx = $rng.Next(-$power, $power + 1)
        $dy = $rng.Next(-$power, $power + 1)
        [M]::SetCursorPos($originX + $dx, $originY + $dy)
        Start-Sleep -Milliseconds 15
    }
    [M]::SetCursorPos($originX, $originY)
} else {
    $proc = Get-Process -Name $app -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $proc) { exit }
    $hwnd = $proc.MainWindowHandle
    if ($hwnd -eq 0) { exit }
    $src = @"
using System;
using System.Runtime.InteropServices;
public class WindowShake {
    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hwnd, out RECT rect);
    public struct RECT { public int Left, Top, Right, Bottom; }
}
"@
    try {
        Add-Type -TypeDefinition $src -ErrorAction Stop
    } catch {
        exit
    }
    $rect = New-Object WindowShake+RECT
    [WindowShake]::GetWindowRect($hwnd, [ref]$rect)
    $origX = $rect.Left
    $origY = $rect.Top
    $origW = $rect.Right - $rect.Left
    $origH = $rect.Bottom - $rect.Top
    $includeSize = [bool]$p.IncludeSize
    $end = (Get-Date).AddSeconds($time)
    $rng = New-Object System.Random
    while ((Get-Date) -lt $end) {
        $dx = $rng.Next(-$power, $power+1)
        $dy = $rng.Next(-$power, $power+1)
        $newX = $origX + $dx
        $newY = $origY + $dy
        $newW = $origW
        $newH = $origH
        if ($includeSize) {
            $dw = $rng.Next(-$power, $power+1)
            $dh = $rng.Next(-$power, $power+1)
            $newW = $origW + $dw
            $newH = $origH + $dh
        }
        [WindowShake]::SetWindowPos($hwnd, [IntPtr]::Zero, $newX, $newY, $newW, $newH, 0x0004)
        Start-Sleep -Milliseconds 15
    }
    [WindowShake]::SetWindowPos($hwnd, [IntPtr]::Zero, $origX, $origY, $origW, $origH, 0x0004)
}