$uid = $args[0]
$p = Get-Content "$PSScriptRoot\params_$uid.json" | ConvertFrom-Json

Add-Type -AssemblyName System.Windows.Forms

$fullMsg = $p.msg
$typeSpeed = if ($p.PSObject.Properties["typespeed"]) { $p.typespeed } else { 0 }
$closeTime = if ($p.PSObject.Properties["closeTime"]) { $p.closeTime } else { 3 }
$useNotepad = if ($p.PSObject.Properties["notepad"]) { $p.notepad } else { $false }

if ($useNotepad) {
    $notepadProc = Start-Process notepad -PassThru
    Start-Sleep -Milliseconds 800

    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class NotepadHelper {
    [DllImport("user32.dll")] public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr child, string cls, string title);
    [DllImport("user32.dll")] public static extern int SendMessage(IntPtr hWnd, int msg, int wParam, string lParam);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@

    $notepadHwnd = $notepadProc.MainWindowHandle
    $editHwnd = [NotepadHelper]::FindWindowEx($notepadHwnd, [IntPtr]::Zero, "Edit", $null)
    if ($editHwnd -eq [IntPtr]::Zero) {
        $scintilla = [NotepadHelper]::FindWindowEx($notepadHwnd, [IntPtr]::Zero, "Scintilla", $null)
        if ($scintilla -ne [IntPtr]::Zero) { $editHwnd = $scintilla }
    }

    [NotepadHelper]::SetForegroundWindow($notepadHwnd) | Out-Null

    $form2 = New-Object System.Windows.Forms.Form
    $form2.Text = $p.title
    $form2.Size = New-Object System.Drawing.Size(400, 200)
    $form2.StartPosition = "CenterScreen"
    $form2.TopMost = $true
    if ($p.closable -eq $false) { $form2.ControlBox = $false }

    $label2 = New-Object System.Windows.Forms.Label
    $label2.Text = ""
    $label2.Dock = "Fill"
    $label2.TextAlign = "MiddleCenter"
    $label2.Font = New-Object System.Drawing.Font("Arial", 12)
    $form2.Controls.Add($label2)

    $charIndex = 0
    $typingDone = $false

    $typeTimer = New-Object System.Windows.Forms.Timer
    $typeTimer.Interval = if ($typeSpeed -le 0) { 1 } else { $typeSpeed }
    $typeTimer.Add_Tick({
        if ($charIndex -lt $fullMsg.Length) {
            $ch = $fullMsg[$charIndex].ToString()
            $label2.Text += $ch
            if ($editHwnd -ne [IntPtr]::Zero) {
                [NotepadHelper]::SendMessage($editHwnd, 0x000C, 0, $label2.Text) | Out-Null
            }
            $script:charIndex++
        } else {
            $typeTimer.Stop()
            $script:typingDone = $true
            if ($closeTime -ge 0) {
                $closeTimer = New-Object System.Windows.Forms.Timer
                $closeTimer.Interval = $closeTime * 1000
                $closeTimer.Add_Tick({ $form2.Close() })
                $closeTimer.Start()
            }
        }
    })
    $typeTimer.Start()

    $form2.ShowDialog()
    $typeTimer.Stop()

} else {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $p.title
    $form.Size = New-Object System.Drawing.Size(400, 200)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    if ($p.closable -eq $false) { $form.ControlBox = $false }

    $label = New-Object System.Windows.Forms.Label
    $label.Text = ""
    $label.Dock = "Fill"
    $label.TextAlign = "MiddleCenter"
    $label.Font = New-Object System.Drawing.Font("Arial", 12)
    $form.Controls.Add($label)

    $charIndex = 0

    $typeTimer = New-Object System.Windows.Forms.Timer
    $typeTimer.Interval = if ($typeSpeed -le 0) { 1 } else { $typeSpeed }
    $typeTimer.Add_Tick({
        if ($charIndex -lt $fullMsg.Length) {
            $label.Text += $fullMsg[$charIndex].ToString()
            $script:charIndex++
        } else {
            $typeTimer.Stop()
            if ($closeTime -ge 0) {
                $closeTimer = New-Object System.Windows.Forms.Timer
                $closeTimer.Interval = $closeTime * 1000
                $closeTimer.Add_Tick({ $form.Close() })
                $closeTimer.Start()
            }
        }
    })
    $typeTimer.Start()

    $form.ShowDialog()
    $typeTimer.Stop()
}