$uid = $args[0]
if (-not $uid) { exit }

try {
    $p = Get-Content "$PSScriptRoot\params_$uid.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
    if (-not $p) { exit }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $logoPath = "$env:TEMP\logo_$uid.ico"

    try {
        if ($p.logo) {
            $tempPng = "$env:TEMP\temp_$uid.png"

            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($p.logo, $tempPng)
            $wc.Dispose()

            if (Test-Path $tempPng) {
                $bmp = New-Object System.Drawing.Bitmap($tempPng)
                $icon = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())

                $fs = [System.IO.File]::Create($logoPath)
                $icon.Save($fs)
                $fs.Close()

                $bmp.Dispose()
                $icon.Dispose()

                Remove-Item $tempPng -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {}

    $notify = New-Object System.Windows.Forms.NotifyIcon

    try {
        if (Test-Path $logoPath) {
            $notify.Icon = New-Object System.Drawing.Icon($logoPath)
        } else {
            $notify.Icon = [System.Drawing.SystemIcons]::Application
        }
    } catch {
        $notify.Icon = [System.Drawing.SystemIcons]::Application
    }

    $notify.Visible = $true

    Start-Sleep -Milliseconds 750

    $notify.BalloonTipTitle = [string]$p.title
    $notify.BalloonTipText = [string]$p.text
    $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info

    $global:clicked = $false

    $event = Register-ObjectEvent -InputObject $notify -EventName BalloonTipClicked -Action {
        $global:clicked = $true
    }

    $duration = [Math]::Max(1, [int]$p.time)

    $notify.ShowBalloonTip($duration * 1000)

    $sw = [Diagnostics.Stopwatch]::StartNew()

    while ($sw.Elapsed.TotalSeconds -lt $duration) {
        [System.Windows.Forms.Application]::DoEvents()

        if ($global:clicked) {
            break
        }

        Start-Sleep -Milliseconds 50
    }

    if ($global:clicked -and $p.connectionId) {
        @{
            connectionId = $p.connectionId
            answer = "clicked"
        } | ConvertTo-Json -Compress | Set-Content "$PSScriptRoot\..\response_$($p.connectionId).json" -Encoding UTF8
    }

    if ($event) {
        Unregister-Event -SourceIdentifier $event.Name -ErrorAction SilentlyContinue
    }

    $notify.Visible = $false
    $notify.Dispose()

    if (Test-Path $logoPath) {
        Remove-Item $logoPath -Force -ErrorAction SilentlyContinue
    }
} catch {
}