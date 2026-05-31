$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds

$bmp = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
$g.Dispose()

$form = New-Object System.Windows.Forms.Form
$form.WindowState = 'Maximized'
$form.FormBorderStyle = 'None'
$form.TopMost = $true
$form.ShowInTaskbar = $false

$pic = New-Object System.Windows.Forms.PictureBox
$pic.Dock = 'Fill'
$pic.Image = $bmp
$pic.SizeMode = 'StretchImage'

$form.Controls.Add($pic)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = [int]$p.Time * 1000

$timer.Add_Tick({
    $timer.Stop()
    $form.Close()
})

$form.Add_Shown({
    $timer.Start()
})

[System.Windows.Forms.Application]::Run($form)