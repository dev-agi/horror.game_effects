$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json

$code = @"
using System;
using System.Runtime.InteropServices;

public class WindowManager {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern int GetWindowLong(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll")]
    public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
}
"@
Add-Type -TypeDefinition $code

$process = Get-Process -Name $p.App -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1

if ($process) {
    $hWnd = $process.MainWindowHandle
    
    $GWL_STYLE = -16
    $WS_THICKFRAME = 0x00040000
    $WS_MAXIMIZEBOX = 0x00010000
    
    $originalStyle = [WindowManager]::GetWindowLong($hWnd, $GWL_STYLE)

    if ($p.BypassScreenSizeLimits -eq $true) {
        $modStyle = $originalStyle -band -bnot $WS_THICKFRAME -band -bnot $WS_MAXIMIZEBOX
        [WindowManager]::SetWindowLong($hWnd, $GWL_STYLE, $modStyle)
    }

    $rect = New-Object WindowManager+RECT
    [WindowManager]::GetWindowRect($hWnd, [ref]$rect)
    
    $startX = $rect.Right - $rect.Left
    $startY = $rect.Bottom - $rect.Top
    $startLeft = $rect.Left
    $startTop = $rect.Top

    $centerX = $startLeft + ($startX / 2)
    $centerY = $startTop + ($startY / 2)

    $targetLeft = $centerX - ($p.SizeX / 2)
    $targetTop = $centerY - ($p.SizeY / 2)

    $duration = $p.TweenTime * 1000
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    while ($sw.ElapsedMilliseconds -lt $duration) {
        $alpha = $sw.ElapsedMilliseconds / $duration
        if ($alpha -gt 1) { $alpha = 1 }

        $t = if ($alpha -lt 0.5) {
            2 * $alpha * $alpha
        } else {
            1 - [Math]::Pow(-2 * $alpha + 2, 2) / 2
        }

        $currentX = [int]($startX + ($p.SizeX - $startX) * $t)
        $currentY = [int]($startY + ($p.SizeY - $startY) * $t)
        $currentLeft = [int]($startLeft + ($targetLeft - $startLeft) * $t)
        $currentTop = [int]($startTop + ($targetTop - $startTop) * $t)
        
        [WindowManager]::SetWindowPos($hWnd, [IntPtr]::Zero, $currentLeft, $currentTop, $currentX, $currentY, 0x0040)
        [System.Threading.Thread]::Sleep(1)
    }

    [WindowManager]::SetWindowPos($hWnd, [IntPtr]::Zero, [int]$targetLeft, [int]$targetTop, [int]$p.SizeX, [int]$p.SizeY, 0x0040)
    $sw.Stop()

    if ($p.BypassScreenSizeLimits -eq $true) {
        [WindowManager]::SetWindowLong($hWnd, $GWL_STYLE, $originalStyle)
    }

    if ($p.FixAfterTween -eq $true) {
        [WindowManager]::SetWindowPos($hWnd, [IntPtr]::Zero, $startLeft, $startTop, $startX, $startY, 0x0040)
    }
} else {
    Write-Host "Process not found: $($p.App)"
}