Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json
$connectionId = $p.connectionId
$responseFile = "$PSScriptRoot\..\response_$connectionId.json"

$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Menu"
$mainForm.Width = 300
$mainForm.Height = 250
$mainForm.StartPosition = "CenterScreen"
$mainForm.FormBorderStyle = "FixedDialog"
$mainForm.MaximizeBox = $false
$mainForm.MinimizeBox = $false

if ($p.Menu.LockSize) {
    $mainForm.MaximumSize = $mainForm.Size
    $mainForm.MinimumSize = $mainForm.Size
}

if ($p.HTML -eq $true) {
    $webBrowser = New-Object System.Windows.Forms.WebBrowser
    $webBrowser.Dock = [System.Windows.Forms.DockStyle]::Fill
    $webBrowser.ScrollBarsEnabled = $false

    $buttonsHtml = ""
    $answersObj = $p.Answers
    $properties = $answersObj | Get-Member -MemberType NoteProperty
    foreach ($prop in $properties) {
        $btnId = $prop.Name
        $btnText = $answersObj.$btnId
        $buttonsHtml += "<button onclick='window.external.Select(`"$btnId`")' style='display:block; width:90%; margin:10px auto; padding:8px;'>$btnText</button>"
    }

    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #fff; }
        button { cursor: pointer; }
    </style>
</head>
<body>
    <div>$($p.Question)</div>
    <div style='margin-top:20px;'>$buttonsHtml</div>
</body>
</html>
"@

    $scriptObject = New-Object -TypeName PSObject
    $scriptObject | Add-Member -MemberType ScriptMethod -Name Select -Value {
        param($id)
        @{ connectionId = $connectionId; selected = $id } | ConvertTo-Json | Out-File $responseFile -Encoding utf8
        $mainForm.Close()
    }

    $webBrowser.ObjectForScripting = $scriptObject
    $webBrowser.DocumentText = $htmlContent
    $mainForm.Controls.Add($webBrowser)
} else {
    $cleanQuestion = $p.Question -replace '<[^>]*>', ''
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $cleanQuestion
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Size = New-Object System.Drawing.Size(240, 40)
    $label.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $mainForm.Controls.Add($label)

    $yPos = 80
    $answersObj = $p.Answers
    $properties = $answersObj | Get-Member -MemberType NoteProperty

    foreach ($prop in $properties) {
        $btnId = $prop.Name
        $rawText = $answersObj.$btnId
        $cleanText = $rawText -replace '<[^>]*>', ''

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $cleanText
        $btn.Location = New-Object System.Drawing.Point(20, $yPos)
        $btn.Size = New-Object System.Drawing.Size(240, 35)
        $btn.add_Click({
            $scriptObject | Add-Member -MemberType ScriptMethod -Name Select -Value {
                param($id)
                @{ connectionId = $connectionId; selected = $id } | ConvertTo-Json | Out-File $responseFile -Encoding utf8
                $mainForm.Close()
            }
            $mainForm.Close()
        }.GetNewClosure())
        $mainForm.Controls.Add($btn)
        $yPos += 45
    }
}

if ($p.Menu.VisibleTime -gt 0) {
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = $p.Menu.VisibleTime * 1000
    $timer.add_Tick({ $mainForm.Close() })
    $timer.Start()
}

$mainForm.ShowDialog()