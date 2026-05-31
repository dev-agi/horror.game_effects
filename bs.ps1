$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.WindowState = 'Maximized'
$form.FormBorderStyle = 'None'
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.BackColor = "Black"

$form.Add_Shown({
    Start-Sleep -Milliseconds 150

    [System.Windows.Forms.Cursor]::Hide()

    $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)

    $g.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
    $g.Dispose()

    $pic = New-Object System.Windows.Forms.PictureBox
    $pic.Dock = 'Fill'
    $pic.Image = $bmp
    $pic.SizeMode = 'StretchImage'

    $form.Controls.Add($pic)
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = [int]$p.Time * 1000

$timer.Add_Tick({
    $timer.Stop()
    [System.Windows.Forms.Cursor]::Show()
    $form.Close()
})

$form.Add_FormClosed({
    [System.Windows.Forms.Cursor]::Show()
})

$timer.Start()

[System.Windows.Forms.Application]::Run($form)