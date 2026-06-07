$uid = $args[0]
$p = $null

if ($uid) {
    $p = Get-Content "$PSScriptRoot\params_$uid.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
}

$title   = "HorrorGame"
$text    = "He is watching you.."
$time    = 10
$iconUrl = "https://clipart-library.com/new_gallery/20-202034_eye-red-scary-vampire-redeyes-eyecolor-eyeball-iridology.png"

if ($null -ne $p) {
    if ($p.title) { $title   = $p.title }
    if ($p.text)  { $text    = $p.text  }
    if ($p.time)  { $time    = $p.time  }
    if ($p.icon)  { $iconUrl = $p.icon  }
}

$appId   = "HorrorGame.Notifier"
$appName = "HorrorGame"
$regPath = "HKCU:\SOFTWARE\Classes\AppUserModelId\$appId"

if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
    New-ItemProperty -Path $regPath -Name "DisplayName"       -Value $appName -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $regPath -Name "ShowInSettings"    -Value 1        -PropertyType DWord  -Force | Out-Null
    New-ItemProperty -Path $regPath -Name "AllowContentAboveLock" -Value 1   -PropertyType DWord  -Force | Out-Null
}

$tempImg = $null

try {
    Add-Type -AssemblyName System.Drawing

    if ($iconUrl) {
        $tempImg = Join-Path $env:TEMP "notif_icon_$(Get-Random).png"
        try {
            Invoke-WebRequest -Uri $iconUrl -OutFile $tempImg -UseBasicParsing
        } catch {
            $tempImg = $null
        }
    }

    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType=WindowsRuntime] | Out-Null

    if ($tempImg -and (Test-Path $tempImg)) {
        $imgUri = "file:///" + $tempImg.Replace("\", "/")
        $xml = @"
<toast duration="long">
  <visual>
    <binding template="ToastGeneric">
      <text>$title</text>
      <text>$text</text>
      <image placement="appLogoOverride" hint-crop="circle" src="$imgUri"/>
    </binding>
  </visual>
</toast>
"@
    } else {
        $xml = @"
<toast duration="long">
  <visual>
    <binding template="ToastGeneric">
      <text>$title</text>
      <text>$text</text>
    </binding>
  </visual>
</toast>
"@
    }

    $xmlDoc = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xmlDoc.LoadXml($xml)

    $toast = New-Object Windows.UI.Notifications.ToastNotification($xmlDoc)

    $global:clicked = $false
    $toast.add_Activated({ $global:clicked = $true })

    $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId)
    $notifier.Show($toast)

    $startTime = Get-Date
    while ((((Get-Date) - $startTime).TotalSeconds -lt $time) -and (-not $global:clicked)) {
        Start-Sleep -Milliseconds 100
    }

    if ($global:clicked -and ($null -ne $p) -and $p.connectionId) {
        @{
            connectionId = $p.connectionId
            answer       = "clicked"
        } | ConvertTo-Json -Compress | Set-Content "$PSScriptRoot\..\response_$($p.connectionId).json" -Encoding UTF8
    }

} catch {}

Start-Sleep -Seconds 1

if ($tempImg -and (Test-Path $tempImg)) { Remove-Item $tempImg -Force -ErrorAction SilentlyContinue }