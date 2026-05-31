$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json

$duration = $p.Time

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$screens = [System.Windows.Forms.Screen]::AllScreens

$forms = @()

foreach ($screen in $screens) {
    $form = New-Object System.Windows.Forms.Form
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
    $form.TopMost = $true
    $form.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
    $form.Bounds = $screen.Bounds
    $form.ShowInTaskbar = $false
    $form.Cursor = [System.Windows.Forms.Cursors]::Default

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $panel.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)

    $labelEmoji = New-Object System.Windows.Forms.Label
    $labelEmoji.Text = ":("
    $labelEmoji.Font = New-Object System.Drawing.Font("Segoe UI", 120, [System.Drawing.FontStyle]::Regular)
    $labelEmoji.ForeColor = [System.Drawing.Color]::White
    $labelEmoji.AutoSize = $true
    $labelEmoji.Location = New-Object System.Drawing.Point(180, 80)

    $labelMsg = New-Object System.Windows.Forms.Label
    $labelMsg.Text = "Your PC ran into a problem and needs to restart. We're`njust collecting some error info, and then we'll restart for you."
    $labelMsg.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Regular)
    $labelMsg.ForeColor = [System.Drawing.Color]::White
    $labelMsg.AutoSize = $true
    $labelMsg.Location = New-Object System.Drawing.Point(180, 320)

    $labelPercent = New-Object System.Windows.Forms.Label
    $labelPercent.Text = "0% complete"
    $labelPercent.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Regular)
    $labelPercent.ForeColor = [System.Drawing.Color]::White
    $labelPercent.AutoSize = $true
    $labelPercent.Location = New-Object System.Drawing.Point(180, 420)

    $labelCode = New-Object System.Windows.Forms.Label
    $labelCode.Text = "For more information about this issue and possible fixes, visit`nhttps://www.windows.com/stopcode`n`nIf you call a support person, give them this info:`nStop code: CRITICAL_PROCESS_DIED"
    $labelCode.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $labelCode.ForeColor = [System.Drawing.Color]::White
    $labelCode.AutoSize = $true
    $labelCode.Location = New-Object System.Drawing.Point(180, 520)

    $panel.Controls.Add($labelEmoji)
    $panel.Controls.Add($labelMsg)
    $panel.Controls.Add($labelPercent)
    $panel.Controls.Add($labelCode)
    $form.Controls.Add($panel)

    $forms += [PSCustomObject]@{ Form = $form; Label = $labelPercent }
}

foreach ($f in $forms) {
    $f.Form.Show()
}

$startTime = Get-Date
$endTime = $startTime.AddSeconds($duration)

while ((Get-Date) -lt $endTime) {
    $elapsed = ((Get-Date) - $startTime).TotalSeconds
    $percent = [math]::Min([math]::Round(($elapsed / $duration) * 100), 100)

    foreach ($f in $forms) {
        $f.Label.Text = "$percent% complete"
        $f.Form.Refresh()
    }

    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 500
}

foreach ($f in $forms) {
    $f.Form.Close()
    $f.Form.Dispose()
}