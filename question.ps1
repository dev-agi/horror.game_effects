Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$uid = $args[0]
$p = Get-Content "$PSScriptRoot\params_$uid.json" -Raw | ConvertFrom-Json

$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Question"
$mainForm.Size = New-Object System.Drawing.Size($p.Menu.AppSize.X, $p.Menu.AppSize.Y)
$mainForm.StartPosition = "CenterScreen"
$mainForm.ControlBox = $false
$mainForm.TopMost = $true

if ($p.Menu.LockSize) {
    $mainForm.FormBorderStyle = "FixedSingle"
    $mainForm.MaximizeBox = $false
    $mainForm.MinimizeBox = $false
}

$bgColorR = [int]($p.Menu.BackgroundColor.R * 255)
$bgColorG = [int]($p.Menu.BackgroundColor.G * 255)
$bgColorB = [int]($p.Menu.BackgroundColor.B * 255)
$mainForm.BackColor = [System.Drawing.Color]::FromArgb($bgColorR, $bgColorG, $bgColorB)

$webBrowser = New-Object System.Windows.Forms.WebBrowser
$webBrowser.Width = [int]($p.Menu.AppSize.X) - 40
$webBrowser.Height = 120
$webBrowser.Location = New-Object System.Drawing.Point(20, 20)
$webBrowser.ScrollBarsEnabled = $false
$webBrowser.ScriptErrorsSuppressed = $true
$webBrowser.DocumentText = "<html><body style='background-color:rgb($bgColorR,$bgColorG,$bgColorB); font-family:sans-serif; margin:0; padding:0;'>$($p.Question)</body></html>"
$mainForm.Controls.Add($webBrowser)

$answersObj = $p.Answers
$buttonY = 160
$buttonWidth = [int]($p.Menu.AppSize.X) - 40

foreach ($prop in $answersObj.PSObject.Properties) {
    $ansId = $prop.Name
    $ansData = $prop.Value
    
    if ($ansData.Text) {
        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $ansData.Text
        $btn.Size = New-Object System.Drawing.Size($buttonWidth, 45)
        $btn.Location = New-Object System.Drawing.Point(20, $buttonY)
        $btn.FlatStyle = "Flat"
        $btn.Font = New-Object System.Drawing.Size("Arial", 11)
        
        $btnBgR = [int]($ansData.BackgroundColor.R * 255)
        $btnBgG = [int]($ansData.BackgroundColor.G * 255)
        $btnBgB = [int]($ansData.BackgroundColor.B * 255)
        $btn.BackColor = [System.Drawing.Color]::FromArgb($btnBgR, $btnBgG, $btnBgB)
        
        if ($ansData.BorderColor) {
            $btnBdR = [int]($ansData.BorderColor.R * 255)
            $btnBdG = [int]($ansData.BorderColor.G * 255)
            $btnBdB = [int]($ansData.BorderColor.B * 255)
            $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb($btnBdR, $btnBdG, $btnBdB)
        }
        
        $btn.Add_Click({
            $response = @{
                connectionId = $p.connectionId
                selected = $ansId
            } | ConvertTo-Json -Compress
            
            [System.IO.File]::WriteAllText("$PSScriptRoot\..\response_$($p.connectionId).json", $response)
            $mainForm.Close()
        })
        
        $mainForm.Controls.Add($btn)
        $buttonY += 55
    }
}

$mainForm.ShowDialog()