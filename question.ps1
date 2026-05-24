Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$uid = $args[0]
$jsonPath = "$PSScriptRoot\params_$uid.json"

Write-Host "=================== DEBUG BASLADI ===================" -ForegroundColor Cyan
Write-Host "Okunacak dosya yolu: $jsonPath"

if (-not (Test-Path $jsonPath)) {
    Write-Host "HATA: JSON dosyasi bulunamadi!" -ForegroundColor Red
    exit
}

$rawJson = Get-Content $jsonPath -Raw -Encoding utf8
Write-Host "Roblox'tan Gelen Ham JSON İçeriği:" -ForegroundColor Yellow
Write-Host $rawJson

try {
    $p = ConvertFrom-Json $rawJson
    Write-Host "JSON basariyla nesneye donusturuldu." -ForegroundColor Green
} catch {
    Write-Host "HATA: JSON donusumu sirasinda hata olustu: $_" -ForegroundColor Red
}

# Boyut Ayıklama Debug
$width = 500
$height = 500
if ($p.Menu.AppSize.X) { 
    $width = [int]$p.Menu.AppSize.X 
    Write-Host "Gelen Genislik (X): $width" -ForegroundColor Green
} else {
    Write-Host "UYARI: AppSize.X bulunamadi, varsayilan (500) kullaniliyor." -ForegroundColor Magenta
}
if ($p.Menu.AppSize.Y) { 
    $height = [int]$p.Menu.AppSize.Y 
    Write-Host "Gelen Yukseklik (Y): $height" -ForegroundColor Green
} else {
    Write-Host "UYARI: AppSize.Y bulunamadi, varsayilan (500) kullaniliyor." -ForegroundColor Magenta
}

$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Question - Debug Mode"
$mainForm.Size = New-Object System.Drawing.Size($width, $height)
$mainForm.StartPosition = "CenterScreen"
$mainForm.ControlBox = $false
$mainForm.TopMost = $true

if ($p.Menu.LockSize) {
    $mainForm.FormBorderStyle = "FixedSingle"
    $mainForm.MaximizeBox = $false
    $mainForm.MinimizeBox = $false
}

# Arka Plan Rengi Debug
$bgColor = [System.Drawing.Color]::FromArgb(127, 127, 127)
if ($p.Menu.BackgroundColor) {
    $bgR = if ($p.Menu.BackgroundColor.R -le 1) { [int]($p.Menu.BackgroundColor.R * 255) } else { [int]$p.Menu.BackgroundColor.R }
    $bgG = if ($p.Menu.BackgroundColor.G -le 1) { [int]($p.Menu.BackgroundColor.G * 255) } else { [int]$p.Menu.BackgroundColor.G }
    $bgB = if ($p.Menu.BackgroundColor.B -le 1) { [int]($p.Menu.BackgroundColor.B * 255) } else { [int]$p.Menu.BackgroundColor.B }
    $bgColor = [System.Drawing.Color]::FromArgb($bgR, $bgG, $bgB)
    Write-Host "Arka Plan Rengi Hesaplandi: R=$bgR, G=$bgG, B=$bgB" -ForegroundColor Green
} else {
    Write-Host "UYARI: BackgroundColor bulunamadi, varsayilan gri renk kullaniliyor." -ForegroundColor Magenta
}
$mainForm.BackColor = $bgColor

# Soru Basligi Debug
Write-Host "Gelen Soru Metni: $($p.Question)" -ForegroundColor Green
$lblQuestion = New-Object System.Windows.Forms.Label
$lblQuestion.Text = if ($p.Question) { $p.Question } else { "Soru yüklenemedi?" }
$lblQuestion.Width = $width - 40
$lblQuestion.Height = 80
$lblQuestion.Location = New-Object System.Drawing.Point(20, 40)
$lblQuestion.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
$lblQuestion.ForeColor = [System.Drawing.Color]::White
$lblQuestion.TextAlign = "MiddleCenter"
$mainForm.Controls.Add($lblQuestion)

# Butonlar / Cevaplar Debug
$buttonY = 160
$buttonWidth = $width - 40

if ($p.Answers) {
    $properties = $p.Answers.PSObject.Properties
    Write-Host "Tespit edilen secenek sayisi: $($properties.Count)" -ForegroundColor Green
    
    foreach ($prop in $properties) {
        $ansId = $prop.Name
        $ansData = $prop.Value
        Write-Host "Secenek Islemesi -> ID: $ansId, Metin: $($ansData.Text)" -ForegroundColor Yellow
        
        if ($ansData.Text) {
            $btn = New-Object System.Windows.Forms.Button
            $btn.Text = $ansData.Text
            $btn.Size = New-Object System.Drawing.Size($buttonWidth, 50)
            $btn.Location = New-Object System.Drawing.Point(20, $buttonY)
            $btn.FlatStyle = "Flat"
            $btn.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
            $btn.ForeColor = [System.Drawing.Color]::White
            
            $btnBgColor = [System.Drawing.Color]::DimGray
            if ($ansData.BackgroundColor) {
                $bR = if ($ansData.BackgroundColor.R -le 1) { [int]($ansData.BackgroundColor.R * 255) } else { [int]$ansData.BackgroundColor.R }
                $bG = if ($ansData.BackgroundColor.G -le 1) { [int]($ansData.BackgroundColor.G * 255) } else { [int]$ansData.BackgroundColor.G }
                $bB = if ($ansData.BackgroundColor.B -le 1) { [int]($ansData.BackgroundColor.B * 255) } else { [int]$ansData.BackgroundColor.B }
                $btnBgColor = [System.Drawing.Color]::FromArgb($bR, $bG, $bB)
            }
            $btn.BackColor = $btnBgColor
            
            if ($ansData.BorderColor) {
                $bdR = if ($ansData.BorderColor.R -le 1) { [int]($ansData.BorderColor.B * 255) } else { [int]$ansData.BorderColor.R }
                $bdG = if ($ansData.BorderColor.G -le 1) { [int]($ansData.BorderColor.G * 255) } else { [int]$ansData.BorderColor.G }
                $bdB = if ($ansData.BorderColor.B -le 1) { [int]($ansData.BorderColor.B * 255) } else { [int]$ansData.BorderColor.B }
                $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb($bdR, $bdG, $bdB)
            }
            
            # Tiklama Olayi Loglamasi
            $btn.Add_Click({
                Write-Host "Butona basildi! Secilen ID: $ansId" -ForegroundColor Green
                $outputPath = "$PSScriptRoot\..\response_$($p.connectionId).json"
                
                $response = @{
                    connectionId = $p.connectionId
                    selected = $ansId
                } | ConvertTo-Json -Compress
                
                Write-Host "Yazilacak Cevap Dosyasi: $outputPath" -ForegroundColor Yellow
                Write-Host "Yazilacak Cevap Icerigi: $response" -ForegroundColor Yellow
                
                [System.IO.File]::WriteAllText($outputPath, $response)
                Write-Host "Cevap dosyasi basariyla yazildi. Form kapatiliyor..." -ForegroundColor Green
                $mainForm.Close()
            })
            
            $mainForm.Controls.Add($btn)
            $buttonY += 65
        }
    }
} else {
    Write-Host "HATA: JSON icinde 'Answers' objesi bulunamadi!" -ForegroundColor Red
}

Write-Host "Form gosteriliyor (ShowDialog)..." -ForegroundColor Cyan
$mainForm.ShowDialog()
Write-Host "=================== DEBUG BITTI ===================" -ForegroundColor Cyan