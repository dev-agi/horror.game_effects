$uid = $args[0]
if (-not $uid) { exit }

try {
    $p = Get-Content "$PSScriptRoot\params_$uid.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
    if (-not $p) { exit }

    $logoPath = "$env:TEMP\logo_$uid.ico"
    if ($p.logo) {
        $wclient = New-Object System.Net.WebClient
        $wclient.DownloadFile($p.logo, "$env:TEMP\temp_$uid.png")
        if (Test-Path "$env:TEMP\temp_$uid.png") {
            $bmp = New-Object System.Drawing.Bitmap("$env:TEMP\temp_$uid.png")
            $iconHandle = $bmp.GetHicon()
            $icon = [System.Drawing.Icon]::FromHandle($iconHandle)
            $fs = New-Object System.IO.FileStream($logoPath, [System.IO.FileMode]::Create)
            $icon.Save($fs)
            $fs.Close()
            $icon.Dispose()
            $bmp.Dispose()
            Remove-Item "$env:TEMP\temp_$uid.png" -Force -ErrorAction SilentlyContinue
        }
    }

    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

    $notify = New-Object System.Windows.Forms.NotifyIcon
    $notify.Visible = $true

    if (Test-Path $logoPath) {
        try {
            $notify.Icon = New-Object System.Drawing.Icon($logoPath)
        } catch {
            $notify.Icon = [System.Drawing.SystemIcons]::Application
        }
    } else {
        $notify.Icon = [System.Drawing.SystemIcons]::Application
    }

    $appName = $p.title
    $text = $p.text

    $clicked = $false
    $startTime = Get-Date

    $clickedEvent = Register-ObjectEvent -InputObject $notify -EventName "BalloonTipClicked" -Action {
        $global:clicked = $true
    }

    $notify.ShowBalloonTip(($p.time * 1000), $appName, $text, [System.Windows.Forms.ToolTipIcon]::None)

    while (((Get-Date) - $startTime).TotalSeconds -lt $p.time -and -not $global:clicked) {
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 50
    }

    if ($global:clicked) {
        $responsePath = "$PSScriptRoot\..\response_$($p.connectionId).json"
        @{
            connectionId = $p.connectionId
            answer = "clicked"
        } | ConvertTo-Json -Compress | Set-Content $responsePath -Encoding UTF8
    }

    Unregister-Event -SourceIdentifier $clickedEvent.Name -ErrorAction SilentlyContinue
    $notify.Visible = $false
    $notify.Dispose()
    if (Test-Path $logoPath) { Remove-Item $logoPath -Force -ErrorAction SilentlyContinue }
} catch {
    exit
}