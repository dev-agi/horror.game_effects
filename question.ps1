Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$uid = $args[0]
$jsonPath = "$PSScriptRoot\params_$uid.json"

# Dosya okuma hatasini engellemek icin UTF8 ile aciyoruz
$rawJson = Get-Content $jsonPath -Raw -Encoding utf8
$p = ConvertFrom-Json $rawJson

$script:isAnswered = $false

$mainForm = New-Object System.Windows.Forms.Form
# Turkce karakter sorununu tamamen kaldirmak icin basligi degistirdik
$mainForm.Text = "Sistem Mesaji"

# Boyutlari garantiye aliyoruz
$w = 500
$h = 500
if ($p.Menu.AppSize.X) { $w = [int]$p.Menu.AppSize.X }
if ($p.Menu.AppSize.Y) { $h = [int]$p.Menu.AppSize.Y }
$mainForm.ClientSize = New-Object System.Drawing.Size($w, $h)

$mainForm.StartPosition = "CenterScreen"
$mainForm.ControlBox = $false
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
$lblQuestion.Width = $w - 40
$lblQuestion.Height = 60
$lblQuestion.Location = New-Object System.Drawing.Point(20, 30)
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

$startY = [int](($h - $totalButtonsHeight) / 2) + 20
if ($startY -lt 110) { $startY = 110 }

$buttonWidth = $w - 60
$buttonX = 30

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
        $btn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
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
        
        $btn.Add_Click({
            $script:isAnswered = $true
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

$mainForm.Add_FormClosing({
    if (-not $script:isAnswered) {
        $cancelResponse = @{
            connectionId = $p.connectionId
            selected = "canceled"
        } | ConvertTo-Json -Compress
        
        [System.IO.File]::WriteAllText("$PSScriptRoot\..\response_$($p.connectionId).json", $cancelResponse)
    }
})

$mainForm.ShowDialog()