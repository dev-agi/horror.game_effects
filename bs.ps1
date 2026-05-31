$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.WindowState = 'Maximized'
$form.FormBorderStyle = 'None'
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(0, 0, 255)

$label = New-Object System.Windows.Forms.Label
$label.ForeColor = [System.Drawing.Color]::White
$label.BackColor = [System.Drawing.Color]::Transparent
$label.AutoSize = $true
$label.Font = New-Object System.Drawing.Font("Consolas", 18)
$label.Text = "A problem has been detected and Windows has been shut down to prevent damage to your computer.`n`nIf this is the first time you've seen this Stop error screen, restart your computer.`n`nStop code: FAKE_BLUE_SCREEN"

$form.Controls.Add($label)

$form.Add_Shown({
    $label.Left = 50
    $label.Top = 50
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = [int]$p.Time * 1000

$timer.Add_Tick({
    $timer.Stop()
    $form.Close()
})

$timer.Start()

[System.Windows.Forms.Application]::Run($form)