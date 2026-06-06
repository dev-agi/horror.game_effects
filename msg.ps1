$uid = $args[0]
$p = Get-Content "$PSScriptRoot\params_$uid.json" | ConvertFrom-Json

$fullMsg = $p.msg
$typeTime = if ($p.PSObject.Properties["typeTime"]) { [double]$p.typeTime } else { 0 }
$closeTime = if ($p.PSObject.Properties["closeTime"]) { [double]$p.closeTime } else { 3 }
$useNotepad = if ($p.PSObject.Properties["notepad"]) { $p.notepad } else { $false }

Add-Type -AssemblyName System.Windows.Forms

if ($useNotepad) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class NotepadInjector {
    [DllImport("user32.dll")] public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr child, string cls, string title);
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, uint msg, IntPtr wParam, string lParam);
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern int GetClassName(IntPtr hWnd, StringBuilder buf, int max);

    public const uint EM_REPLACESEL = 0x00C2;
    public const uint EM_SETSEL     = 0x00B1;

    public static IntPtr FindEditControl(IntPtr notepadHwnd) {
        string[] classNames = new string[] {
            "RichEditD2DPT", "RichEdit20W", "Edit", "RICHEDIT50W", "RichEdit"
        };
        foreach (string cls in classNames) {
            IntPtr h = FindWindowEx(notepadHwnd, IntPtr.Zero, cls, null);
            if (h != IntPtr.Zero) return h;
        }
        return IntPtr.Zero;
    }

    public static void AppendText(IntPtr editHwnd, string text) {
        SendMessage(editHwnd, EM_SETSEL, new IntPtr(-1), new IntPtr(-1));
        SendMessage(editHwnd, EM_REPLACESEL, new IntPtr(1), text);
    }
}
"@

    $notepadProc = Start-Process notepad -PassThru
    $deadline = (Get-Date).AddSeconds(5)
    $editHwnd = [IntPtr]::Zero

    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 200
        $notepadProc.Refresh()
        $hwnd = $notepadProc.MainWindowHandle
        if ($hwnd -ne [IntPtr]::Zero) {
            $editHwnd = [NotepadInjector]::FindEditControl($hwnd)
            if ($editHwnd -ne [IntPtr]::Zero) { break }
        }
    }

    if ($editHwnd -eq [IntPtr]::Zero) {
        if ($closeTime -ge 0) { Start-Sleep -Seconds $closeTime }
        $notepadProc.CloseMainWindow() | Out-Null
        return
    }

    $intervalMs = 0
    if ($typeTime -gt 0 -and $fullMsg.Length -gt 0) {
        $intervalMs = [int](($typeTime * 1000.0) / $fullMsg.Length)
        if ($intervalMs -lt 1) { $intervalMs = 1 }
    }

    foreach ($ch in $fullMsg.ToCharArray()) {
        [NotepadInjector]::AppendText($editHwnd, $ch.ToString())
        if ($intervalMs -gt 0) { Start-Sleep -Milliseconds $intervalMs }
    }

    if ($closeTime -ge 0) {
        Start-Sleep -Seconds $closeTime
        $notepadProc.CloseMainWindow() | Out-Null
    } else {
        $notepadProc.WaitForExit()
    }

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
    $intervalMs = 1
    if ($typeTime -gt 0 -and $fullMsg.Length -gt 0) {
        $intervalMs = [int](($typeTime * 1000.0) / $fullMsg.Length)
        if ($intervalMs -lt 1) { $intervalMs = 1 }
    }

    $typeTimer = New-Object System.Windows.Forms.Timer
    $typeTimer.Interval = $intervalMs
    $typeTimer.Add_Tick({
        if ($script:charIndex -lt $fullMsg.Length) {
            $label.Text += $fullMsg[$script:charIndex].ToString()
            $script:charIndex++
        } else {
            $typeTimer.Stop()
            if ($closeTime -ge 0) {
                $closeTimer = New-Object System.Windows.Forms.Timer
                $closeTimer.Interval = [int]($closeTime * 1000)
                $closeTimer.Add_Tick({ $form.Close() })
                $closeTimer.Start()
            }
        }
    })
    $typeTimer.Start()
    $form.ShowDialog()
    $typeTimer.Stop()
}