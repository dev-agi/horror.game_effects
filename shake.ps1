$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json
$app = $p.App
$power = [int]$p.Power
$time = [int]$p.Time
$includeSize = [bool]$p.IncludeSize

if ($app -eq "mouse") {
    Add-Type -AssemblyName System.Windows.Forms
    $original = [System.Windows.Forms.Cursor]::Position
    $end = (Get-Date).AddSeconds($time)
    $rng = New-Object System.Random
    while ((Get-Date) -lt $end) {
        $dx = $rng.Next(-$power, $power+1)
        $dy = $rng.Next(-$power, $power+1)
        [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($original.X + $dx, $original.Y + $dy)
        Start-Sleep -Milliseconds 20
    }
    [System.Windows.Forms.Cursor]::Position = $original
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
    public static extern bool GetWindowRect(IntPtr hwnd, ref RECT rectangle);
    public struct RECT { public int Left, Top, Right, Bottom; }
}
"@
    Add-Type -TypeDefinition $source
    $rect = New-Object WindowUtil+RECT
    [WindowUtil]::GetWindowRect($hwnd, [ref]$rect)
    $origX = $rect.Left
    $origY = $rect.Top
    $origW = $rect.Right - $rect.Left
    $origH = $rect.Bottom - $rect.Top
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
        Start-Sleep -Milliseconds 20
    }
    [WindowUtil]::SetWindowPos($hwnd, [IntPtr]::Zero, $origX, $origY, $origW, $origH, 0x0004)
}