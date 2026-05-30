$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json
$app = $p.App
$power = [int]$p.Power
$time = [int]$p.Time

if ($app -eq "mouse") {
    Add-Type -Name WinAPI -MemberDefinition @'
[DllImport("user32.dll")]
public static extern bool SetCursorPos(int x, int y);
[DllImport("user32.dll")]
public static extern bool GetCursorPos(out POINT lpPoint);
public struct POINT { public int X; public int Y; }
'@
    $point = New-Object WinAPI+POINT
    [WinAPI]::GetCursorPos([ref]$point)
    $origX = $point.X
    $origY = $point.Y
    $end = (Get-Date).AddSeconds($time)
    $rng = New-Object System.Random
    while ((Get-Date) -lt $end) {
        $dx = $rng.Next(-$power, $power+1)
        $dy = $rng.Next(-$power, $power+1)
        [WinAPI]::SetCursorPos($origX + $dx, $origY + $dy)
        Start-Sleep -Milliseconds 15
    }
    [WinAPI]::SetCursorPos($origX, $origY)
} else {
    $proc = Get-Process -Name $app -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $proc) { exit }
    $hwnd = $proc.MainWindowHandle
    if ($hwnd -eq 0) { exit }
    $source = @"
using System;
using System.Runtime.InteropServices;
public class WindowUtil {
    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hwnd, out RECT rect);
    public struct RECT { public int Left, Top, Right, Bottom; }
}
"@
    Add-Type -TypeDefinition $source
    [WindowUtil+RECT]$rect = New-Object WindowUtil+RECT
    [WindowUtil]::GetWindowRect($hwnd, [ref]$rect)
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
        [WindowUtil]::SetWindowPos($hwnd, [IntPtr]::Zero, $newX, $newY, $newW, $newH, 0x0004)
        Start-Sleep -Milliseconds 15
    }
    [WindowUtil]::SetWindowPos($hwnd, [IntPtr]::Zero, $origX, $origY, $origW, $origH, 0x0004)
}