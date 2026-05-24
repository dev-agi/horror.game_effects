Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json
$connectionId = $p.connectionId
$responseFile = "$PSScriptRoot\..\response_$connectionId.json"

function RgbToColor($c) {
    return [System.Drawing.Color]::FromArgb([int]($c.R * 255), [int]($c.G * 255), [int]($c.B * 255))
}

$bgColor = RgbToColor $p.Menu.BGColor

$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Menu"
$mainForm.Width = [int]$p.Menu.Size.X
$mainForm.Height = [int]$p.Menu.Size.Y
$mainForm.StartPosition = "CenterScreen"
$mainForm.FormBorderStyle = "FixedDialog"
$mainForm.MaximizeBox = $false
$mainForm.MinimizeBox = $false
$mainForm.TopMost = $true
$mainForm.BackColor = $bgColor

if ($p.Menu.LockSize) {
    $mainForm.MaximumSize = $mainForm.Size
    $mainForm.MinimumSize = $mainForm.Size
}

if ($p.HTML -eq $true) {
    $answersObj = $p.Answers
    $properties = $answersObj | Get-Member -MemberType NoteProperty

    $buttonsHtml = ""
    foreach ($prop in $properties) {
        $btnId = $prop.Name
        $btnData = $answersObj.$btnId
        $bgR = [int]($btnData.BGColor.R * 255)
        $bgG = [int]($btnData.BGColor.G * 255)
        $bgB = [int]($btnData.BGColor.B * 255)
        $txR = [int]($btnData.TextColor.R * 255)
        $txG = [int]($btnData.TextColor.G * 255)
        $txB = [int]($btnData.TextColor.B * 255)
        $boR = [int]($btnData.BorderColor.R * 255)
        $boG = [int]($btnData.BorderColor.G * 255)
        $boB = [int]($btnData.BorderColor.B * 255)
        $radius = $btnData.CornerRadius
        $buttonsHtml += @"
<button onclick="respond('$btnId')" style="
    display:block;
    width:90%;
    margin:8px auto;
    padding:10px;
    background-color:rgb($bgR,$bgG,$bgB);
    color:rgb($txR,$txG,$txB);
    border:2px solid rgb($boR,$boG,$boB);
    border-radius:${radius}px;
    cursor:pointer;
    font-size:14px;
">$($btnData.Text -replace '<[^>]*>','')</button>
"@
    }

    $bgR2 = [int]($p.Menu.BGColor.R * 255)
    $bgG2 = [int]($p.Menu.BGColor.G * 255)
    $bgB2 = [int]($p.Menu.BGColor.B * 255)
    $cleanQuestion = $p.Question -replace '<[^>]*>', ''

    $htmlPath = "$PSScriptRoot\..\question_$connectionId.html"
    $responsePath = $responseFile.Replace('\', '\\')

    @"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
    * { margin:0; padding:0; box-sizing:border-box; }
    body { font-family:Arial,sans-serif; background-color:rgb($bgR2,$bgG2,$bgB2); padding:20px; }
    .question { font-size:16px; font-weight:bold; margin-bottom:15px; text-align:center; }
    button:hover { opacity:0.85; }
</style>
</head>
<body>
<div class="question">$($p.Question)</div>
$buttonsHtml
<script>
function respond(id) {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', 'close_$connectionId?id=' + id, true);
    var fso = new ActiveXObject('Scripting.FileSystemObject');
    var f = fso.CreateTextFile('$responsePath', true);
    f.WriteLine(JSON.stringify({connectionId:'$connectionId',selected:id}));
    f.Close();
    window.close();
}
</script>
</body>
</html>
"@ | Out-File -FilePath $htmlPath -Encoding UTF8

    Start-Process $htmlPath

    if ($p.Menu.VisibleTime -gt 0) {
        Start-Sleep -Seconds $p.Menu.VisibleTime
        if (Test-Path $htmlPath) { Remove-Item $htmlPath -Force }
    }
} else {
    $cleanQuestion = $p.Question -replace '<[^>]*>', ''
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $cleanQuestion
    $label.Location = New-Object System.Drawing.Point(20, 15)
    $label.Size = New-Object System.Drawing.Size(($mainForm.Width - 50), 35)
    $label.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $label.BackColor = $bgColor
    $mainForm.Controls.Add($label)

    $answersObj = $p.Answers
    $properties = $answersObj | Get-Member -MemberType NoteProperty
    $yPos = 60

    foreach ($prop in $properties) {
        $btnId = $prop.Name
        $btnData = $answersObj.$btnId
        $btnBg = RgbToColor $btnData.BGColor
        $btnFg = RgbToColor $btnData.TextColor
        $radius = [int]$btnData.CornerRadius

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = ($btnData.Text -replace '<[^>]*>', '')
        $btn.Location = New-Object System.Drawing.Point(20, $yPos)
        $btn.Size = New-Object System.Drawing.Size(($mainForm.Width - 55), 38)
        $btn.FlatStyle = "Flat"
        $btn.FlatAppearance.BorderColor = RgbToColor $btnData.BorderColor
        $btn.FlatAppearance.BorderSize = 2
        $btn.BackColor = $btnBg
        $btn.ForeColor = $btnFg
        $btn.Font = New-Object System.Drawing.Font("Arial", 10)
        $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
        $btn.Region = [System.Drawing.Region]::FromHrgn(
            (Add-Type -MemberDefinition 'public static extern IntPtr CreateRoundRectRgn(int x1,int y1,int x2,int y2,int cx,int cy);' -Name GDI -Namespace Win32 -PassThru)::CreateRoundRectRgn(0, 0, $btn.Width, $btn.Height, $radius * 2, $radius * 2)
        )
        $btn.add_Click({
            @{ connectionId = $connectionId; selected = $btnId } | ConvertTo-Json | Out-File $responseFile -Encoding utf8
            $mainForm.Close()
        }.GetNewClosure())
        $mainForm.Controls.Add($btn)
        $yPos += 50
    }

    if ($p.Menu.VisibleTime -gt 0) {
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = $p.Menu.VisibleTime * 1000
        $timer.add_Tick({ $mainForm.Close() })
        $timer.Start()
    }
    
    $mainForm.ControlBox = $false
    $mainForm.ShowDialog()
}