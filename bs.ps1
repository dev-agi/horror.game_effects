$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Cursor]::Hide()

$form = New-Object System.Windows.Forms.Form
$form.WindowState = 'Maximized'
$form.FormBorderStyle = 'None'
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.BackColor = "Black"

$pic = New-Object System.Windows.Forms.PictureBox
$pic.Dock = 'Fill'
$pic.SizeMode = 'StretchImage'

$form.Controls.Add($pic)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 50

$captured = $false
$start = Get-Date

$timer.Add_Tick({

    if (-not $captured) {

        $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        $bmp = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
        $g = [System.Drawing.Graphics]::FromImage($bmp)

        $g.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
        $g.Dispose()

        $pic.Image = $bmp
        $captured = $true
    }

    $elapsed = (Get-Date) - $start

    if ($elapsed.TotalSeconds -ge [int]$p.Time) {
        $timer.Stop()
        [System.Windows.Forms.Cursor]::Show()
        $form.Close()
    }
})

$form.Add_Shown({
    Start-Sleep -Milliseconds 200
    $timer.Start()
})

$form.Add_FormClosed({
    [System.Windows.Forms.Cursor]::Show()
})

[System.Windows.Forms.Application]::Run($form)