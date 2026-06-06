$uid = $args[0]
if (-not $uid) { exit }

try {
    $p = Get-Content "$PSScriptRoot\params_$uid.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
    if (-not $p) { exit }

    $logoPath = "$env:TEMP\logo_$uid.png"
    if ($p.logo) {
        $wclient = New-Object System.Net.WebClient
        $wclient.DownloadFile($p.logo, $logoPath)
    }

    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

    $notify = New-Object System.Windows.Forms.NotifyIcon
    $notify.Icon = [System.Drawing.SystemIcons]::Application
    $notify.Visible = $true

    if (Test-Path $logoPath) {
        try {
            $bmp = New-Object System.Drawing.Bitmap($logoPath)
            $hIcon = $bmp.GetHicon()
            $notify.Icon = [System.Drawing.Icon]::FromHandle($hIcon)
        } catch {}
    }

    $notify.BalloonTipTitle = $p.title
    $notify.BalloonTipText = $p.text
    $notify.ShowBalloonTip(($p.time * 1000))

    $clicked = $false
    $startTime = Get-Date

    $clickedEvent = Register-ObjectEvent -InputObject $notify -EventName "BalloonTipClicked" -Action {
        $global:clicked = $true
    }

    while (((Get-Date) - $startTime).TotalSeconds -lt $p.time -and -not $global:clicked) {
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 10
    }

    if ($global:clicked) {
        $responsePath = "$PSScriptRoot\..\response_$($p.connectionId).json"
        @{
            connectionId = $p.connectionId
            answer = "clicked"
        } | ConvertTo-Json -Compress | Set-Content $responsePath -Encoding UTF8
    }

    Unregister-Event -SourceIdentifier $clickedEvent.Name -ErrorAction SilentlyContinue
    $notify.Dispose()
    if (Test-Path $logoPath) { Remove-Item $logoPath -Force -ErrorAction SilentlyContinue }
} catch {
    exit
}