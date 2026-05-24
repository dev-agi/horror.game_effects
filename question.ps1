Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$uid = $args[0]
$p = Get-Content "$PSScriptRoot\params_$uid.json" -Raw | ConvertFrom-Json

# Script genelinde kullanici secim yapti mı kontrolü
$script:isAnswered = $false

$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Sistem Mesajı"
$mainForm.Size = New-Object System.Drawing.Size($p.Menu.AppSize.X, $p.Menu.AppSize.Y)
$mainForm.StartPosition = "CenterScreen"
$mainForm.ControlBox = $true # Test edebilmen veya acik birakabilmen icin true yapildi
$mainForm.TopMost = $true

if ($p.Menu.LockSize) {
    $mainForm.FormBorderStyle = "FixedSingle"
    $mainForm.MaximizeBox = $false
    $mainForm.MinimizeBox = $false
}

$mainForm.BackColor = [System.Drawing.Color]::FromArgb(32, 32, 32)

# Soru Alani
$lblQuestion = New-Object System.Windows.Forms.Label
$lblQuestion.Text = $p.Question
$lblQuestion.Width = [int]($p.Menu.AppSize.X) - 60
$lblQuestion.Height = 80
$lblQuestion.Location = New-Object System.Drawing.Point(30, 40)
$lblQuestion.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblQuestion.ForeColor = [System.Drawing.Color]::White
$lblQuestion.TextAlign = "MiddleCenter"
$mainForm.Controls.Add($lblQuestion)

# Buton Yerlesimi
$answersObj = $p.Answers
$properties = $answersObj.PSObject.Properties
$buttonCount = ($properties | Where-Object { $_.Value.Text }).Count

$btnHeight = 45
$btnSpacing = 15
$totalButtonsHeight = ($buttonCount * $btnHeight) + (($buttonCount - 1) * $btnSpacing)

$startY = [int](($p.Menu.AppSize.Y - $totalButtonsHeight) / 2) + 30
if ($startY -lt 140) { $startY = 140 }

$buttonWidth = [int]($p.Menu.AppSize.X) - 80
$buttonX = 40

foreach ($prop in $properties) {
    $ansId = $prop.Name
    $ansData = $prop.Value
    
    if ($ansData.Text) {
        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $ansData.Text
        $btn.Size = New-Object System.Drawing.Size($buttonWidth, $btnHeight)
        $btn.Location = New-Object System.Drawing.Point($buttonX, $startY)
        $btn.FlatStyle = "Flat"
        $btn.FlatAppearance.BorderSize = 1
        $btn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
        $btn.ForeColor = [System.Drawing.Color]::White
        $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
        
        $btnBgR = [int]($ansData.BackgroundColor.R * 255)
        $btnBgG = [int]($ansData.BackgroundColor.G * 255)
        $btnBgB = [int]($ansData.BackgroundColor.B * 255)
        $btn.BackColor = [System.Drawing.Color]::FromArgb($btnBgR, $btnBgG, $btnBgB)
        
        if ($ansData.BorderColor) {
            $btnBdR = [int]($ansData.BorderColor.R * 255)
            $btnBdG = [int]($ansData.BorderColor.G * 255)
            $btnBdB = [int]($ansData.BorderColor.B * 255)
            $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb($btnBdR, $btnBdG, $btnBdB)
        } else {
            $btn.FlatAppearance.BorderColor = $btn.BackColor
        }
        
        # Normal Buton Tiklamasi
        $btn.Add_Click({
            $script:isAnswered = $true  # Butona basildigini isaretle
            $response = @{
                connectionId = $p.connectionId
                selected = $ansId
            } | ConvertTo-Json -Compress
            
            [System.IO.File]::WriteAllText("$PSScriptRoot\..\response_$($p.connectionId).json", $response)
            $mainForm.Close()
        })
        
        $mainForm.Controls.Add($btn)
        $startY += ($btnHeight + $btnSpacing)
    }
}

# KRITIK COZUM: Oyuncu Formu Butonlara Basmadan Çarpıdan Kapatırsa Tetiklenen Olay
$mainForm.Add_FormClosing({
    if (-not $script:isAnswered) {
        $cancelResponse = @{
            connectionId = $p.connectionId
            selected = "canceled" # Roblox tarafında if answer == "canceled" diyerek yakalayabilirsin
        } | ConvertTo-Json -Compress
        
        [System.IO.File]::WriteAllText("$PSScriptRoot\..\response_$($p.connectionId).json", $cancelResponse)
    }
})

$mainForm.ShowDialog()