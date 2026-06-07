$uid = $args[0]
$p = $null

if ($uid) {
    $p = Get-Content "$PSScriptRoot\params_$uid.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
}

$title = "HorrorGame"
$text = "He is watching you.."
$time = 10

if ($null -ne $p) {
    if ($p.title) { $title = $p.title }
    if ($p.text)  { $text  = $p.text  }
    if ($p.time)  { $time  = $p.time  }
}

try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $notification = New-Object System.Windows.Forms.NotifyIcon
    $notification.Icon = [System.Drawing.SystemIcons]::Application
    $notification.BalloonTipTitle = $title
    $notification.BalloonTipText = $text
    $notification.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::None
    $notification.Visible = $true
    $notification.ShowBalloonTip($time * 1000)

    $global:clicked = $false
    $clickAction = Register-ObjectEvent -InputObject $notification -EventName "BalloonTipClicked" -Action {
        $global:clicked = $true
    }

    $startTime = Get-Date
    while ((((Get-Date) - $startTime).TotalSeconds -lt $time) -and (-not $global:clicked)) {
        Start-Sleep -Milliseconds 100
    }

    if ($global:clicked -and ($null -ne $p) -and $p.connectionId) {
        @{
            connectionId = $p.connectionId
            answer = "clicked"
        } | ConvertTo-Json -Compress | Set-Content "$PSScriptRoot\..\response_$($p.connectionId).json" -Encoding UTF8
    }

    Unregister-Event -SourceIdentifier $clickAction.Name -ErrorAction SilentlyContinue
} catch {}

Start-Sleep -Seconds 1
if ($null -ne $notification) {
    $notification.Visible = $false
    $notification.Dispose()
}