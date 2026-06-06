$uid = $args[0]
$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json

Add-Type -AssemblyName System.Windows.Forms

$form = New-Object System.Windows.Forms.Form
$form.Text = $p.title
$form.Size = New-Object System.Drawing.Size(400, 200)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::White

$label = New-Object System.Windows.Forms.Label
$label.Dock = "Fill"
$label.TextAlign = "MiddleCenter"
$label.Font = New-Object System.Drawing.Font("Arial", 12)
$form.Controls.Add($label)

if ($p.closable -eq $false) { $form.ControlBox = $false }

$closeTimer = New-Object System.Windows.Forms.Timer
$closeTimer.Interval = $p.closeTime * 1000
$closeTimer.Add_Tick({ $closeTimer.Stop(); $form.Close() })

if ($p.notebook -eq $true) {
    $label.Text = ""
    $script:charIndex = 0
    $fullText = $p.msg

    $typeTimer = New-Object System.Windows.Forms.Timer
    $typeTimer.Interval = $p.typespeed
    $typeTimer.Add_Tick({
        if ($script:charIndex -lt $fullText.Length) {
            $label.Text += $fullText[$script:charIndex]
            $script:charIndex++
        } else {
            $typeTimer.Stop()
            $closeTimer.Start()
        }
    })
    $typeTimer.Start()
} else {
    $label.Text = $p.msg
    $closeTimer.Start()
}

$form.ShowDialog()