$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.WindowState = 'Maximized'
$form.FormBorderStyle = 'None'
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$form.Cursor = [System.Windows.Forms.Cursors]::Default

$fontMain = New-Object System.Drawing.Font("Segoe UI", 28)
$fontSmall = New-Object System.Drawing.Font("Segoe UI", 14)

$smiley = New-Object System.Windows.Forms.Label
$smiley.Text = ":("
$smiley.ForeColor = "White"
$smiley.Font = New-Object System.Drawing.Font("Segoe UI", 72)
$smiley.AutoSize = $true
$smiley.Left = 120
$smiley.Top = 80

$text = New-Object System.Windows.Forms.Label
$text.ForeColor = "White"
$text.Font = $fontMain
$text.AutoSize = $true
$text.Text = "Your PC ran into a problem and needs to restart."
$text.Left = 120
$text.Top = 200

$sub = New-Object System.Windows.Forms.Label
$sub.ForeColor = "White"
$sub.Font = $fontSmall
$sub.AutoSize = $true
$sub.Text = "We're just collecting some error info, and then we'll restart for you."
$sub.Left = 120
$sub.Top = 270

$progress = New-Object System.Windows.Forms.Label
$progress.ForeColor = "White"
$progress.Font = $fontSmall
$progress.AutoSize = $true
$progress.Text = "0% complete"
$progress.Left = 120
$progress.Top = 330

$stop = New-Object System.Windows.Forms.Label
$stop.ForeColor = "White"
$stop.Font = $fontSmall
$stop.AutoSize = $true
$stop.Text = "If you'd like to know more, you can search online later for this error: CRITICAL_PROCESS_DIED"
$stop.Left = 120
$stop.Top = 420

$qr = New-Object System.Windows.Forms.Label
$qr.Text = "[ QR CODE ]"
$qr.ForeColor = "White"
$qr.Font = New-Object System.Drawing.Font("Consolas", 12)
$qr.AutoSize = $true
$qr.Left = 120
$qr.Top = 520

$form.Controls.AddRange(@($smiley,$text,$sub,$progress,$stop,$qr))

$percent = 0

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 100

$timer.Add_Tick({
    $percent += 1
    if ($percent -gt 100) {
        $timer.Stop()
        $form.Close()
    }
    $progress.Text = "$percent% complete"
})

$timer.Start()

Start-Sleep -Seconds ([int]$p.Time)

$form.Close()

[System.Windows.Forms.Application]::Run($form)