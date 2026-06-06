$uid = $args[0]
$p = Get-Content "$PSScriptRoot\params_$uid.json" | ConvertFrom-Json

$fullMsg = $p.msg
$typeTime = if ($p.PSObject.Properties["typeTime"]) { [double]$p.typeTime } else { 0 }
$closeTime = if ($p.PSObject.Properties["closeTime"]) { [double]$p.closeTime } else { 3 }
$useNotepad = if ($p.PSObject.Properties["notepad"]) { $p.notepad } else { $false }

Add-Type -AssemblyName System.Windows.Forms

if ($useNotepad) {
    $safeTitle = ($p.title + "_" + $p.connectionId) -replace '[\\/:*?"<>|]', '_'
    $filePath = "$PSScriptRoot\..\notepad_$safeTitle.txt"

    $intervalMs = 0
    if ($typeTime -gt 0 -and $fullMsg.Length -gt 0) {
        $intervalMs = [int](($typeTime * 1000.0) / $fullMsg.Length)
        if ($intervalMs -lt 1) { $intervalMs = 1 }
    }

    $typed = ""
    foreach ($ch in $fullMsg.ToCharArray()) {
        $typed += $ch
        if ($intervalMs -gt 0) { Start-Sleep -Milliseconds $intervalMs }
    }

    [System.IO.File]::WriteAllText($filePath, $typed, [System.Text.Encoding]::UTF8)

    $notepadProc = Start-Process notepad $filePath -PassThru

    if ($closeTime -ge 0) {
        Start-Sleep -Seconds $closeTime
    } else {
        $notepadProc.WaitForExit()
    }

    $notepadProc.CloseMainWindow() | Out-Null
    Start-Sleep -Milliseconds 500
    Remove-Item $filePath -Force -ErrorAction SilentlyContinue

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
    $totalChars = $fullMsg.Length

    $intervalMs = 1
    if ($typeTime -gt 0 -and $totalChars -gt 0) {
        $intervalMs = [int](($typeTime * 1000.0) / $totalChars)
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