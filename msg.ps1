$uid = $args[0]
$paramsFile = "$PSScriptRoot\params_$uid.json"

$p = Get-Content $paramsFile | ConvertFrom-Json

Add-Type -AssemblyName System.Windows.Forms

$form = New-Object System.Windows.Forms.Form
$form.Text = $p.title
$form.Size = New-Object System.Drawing.Size(400,200)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true

$label = New-Object System.Windows.Forms.Label
$label.Text = $p.msg
$label.Dock = "Fill"
$label.TextAlign = "MiddleCenter"
$label.Font = New-Object System.Drawing.Font("Arial", 12)
$form.Controls.Add($label)

if ($p.closable -eq $false) { $form.ControlBox = $false }

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $p.closeTime * 1000
$timer.Add_Tick({ $form.Close() })
$timer.Start()

$form.ShowDialog()