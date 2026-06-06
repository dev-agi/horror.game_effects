$uid = $args[0]
if ($uid) {
    try {
        $p = Get-Content "$PSScriptRoot\params_$uid.json" -Raw | ConvertFrom-Json
        
        $null = [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        $null = [Reflection.Assembly]::LoadWithPartialName("System.Drawing")

        $logoPath = "$env:TEMP\logo_$uid.png"
        if ($p.logo) {
            try {
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($p.logo, $logoPath)
            } catch {
                $logoPath = $null
            }
        } else {
            $logoPath = $null
        }

        $form = New-Object System.Windows.Forms.Form
        $form.Text = $p.title
        $form.Size = New-Object System.Drawing.Size(320, 100)
        $form.StartPosition = "Manual"
        $form.FormBorderStyle = "None"
        $form.ShowInTaskbar = $false
        $form.TopMost = $true
        $form.BackColor = New-Object System.Drawing.Color::FromArgb(20, 20, 20)

        $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
        $form.Location = New-Object System.Drawing.Point(($screen.Width - 330), ($screen.Height - 110))

        if ($logoPath -and (Test-Path $logoPath)) {
            $pb = New-Object System.Windows.Forms.PictureBox
            $pb.Image = [System.Drawing.Image]::FromFile($logoPath)
            $pb.Size = New-Object System.Drawing.Size(60, 60)
            $pb.Location = New-Object System.Drawing.Point(15, 20)
            $pb.SizeMode = "Zoom"
            $form.Controls.Add($pb)
        }

        $lblTitle = New-Object System.Windows.Forms.Label
        $lblTitle.Text = $p.title
        $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $lblTitle.ForeColor = New-Object System.Drawing.Color::White
        $lblTitle.Location = New-Object System.Drawing.Point(85, 15)
        $lblTitle.Size = New-Object System.Drawing.Size(220, 25)
        $form.Controls.Add($lblTitle)

        $lblText = New-Object System.Windows.Forms.Label
        $lblText.Text = $p.text
        $lblText.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $lblText.ForeColor = New-Object System.Drawing.Color::FromArgb(180, 180, 180)
        $lblText.Location = New-Object System.Drawing.Point(85, 40)
        $lblText.Size = New-Object System.Drawing.Size(220, 45)
        $form.Controls.Add($lblText)

        $clicked = $false

        $clickEvent = {
            $script:clicked = $true
            $form.Close()
        }

        $form.Add_Click($clickEvent)
        $lblTitle.Add_Click($clickEvent)
        $lblText.Add_Click($clickEvent)
        if (isset pb) { $pb.Add_Click($clickEvent) }

        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = [int]$p.time * 1000
        $timer.Add_Tick({ $form.Close() })
        $timer.Start()

        $form.ShowDialog()

        if ($clicked) {
            @{
                connectionId = $p.connectionId
                answer = "clicked"
            } | ConvertTo-Json -Compress | Set-Content "$PSScriptRoot\..\response_$($p.connectionId).json" -Encoding UTF8
        }

        if ($logoPath -and (Test-Path $logoPath)) {
            Remove-Item $logoPath -Force
        }
    } catch {}
}