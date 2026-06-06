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

    $appId = $p.title
    $regPath = "HKCU:\Software\Classes\AppId\$appId"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
        New-ItemProperty -Path $regPath -Name "DisplayName" -Value $appId -PropertyType String -Force | Out-Null
    }

    $xml = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text>$($p.title)</text>
            <text>$($p.text)</text>
            $([string]::IsNullOrEmpty($p.logo) ? "" : "<image placement=`"appLogoOverride`" hint-crop=`"circle`" src=`"$logoPath`"/>")
        </binding>
    </visual>
</toast>
"@

    $xmlDoc = New-Object -ComObject Microsoft.XMLDOM
    $xmlDoc.loadXML($xml)

    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Runtime.InteropServices.WindowsRuntime")
    
    $asType = [Type]::GetType("Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime")
    $toastType = [Type]::GetType("Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType=WindowsRuntime")
    $xmlType = [Type]::GetType("Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType=WindowsRuntime")

    $winXml = [Activator]::CreateInstance($xmlType)
    $winXml.LoadXml($xml)

    $toast = [Activator]::CreateInstance($toastType, $winXml)

    $clicked = $false
    $startTime = Get-Date

    $activatedEvent = Register-ObjectEvent -InputObject $toast -EventName "Activated" -Action {
        $global:clicked = $true
    }

    $notifier = $asType::CreateToastNotifier($appId)
    $notifier.Show($toast)

    while (((Get-Date) - $startTime).TotalSeconds -lt $p.time -and -not $global:clicked) {
        Start-Sleep -Milliseconds 50
    }

    if ($global:clicked) {
        $responsePath = "$PSScriptRoot\..\response_$($p.connectionId).json"
        @{
            connectionId = $p.connectionId
            answer = "clicked"
        } | ConvertTo-Json -Compress | Set-Content $responsePath -Encoding UTF8
    }

    Unregister-Event -SourceIdentifier $activatedEvent.Name -ErrorAction SilentlyContinue
    if (Test-Path $logoPath) { Remove-Item $logoPath -Force -ErrorAction SilentlyContinue }
    if (Test-Path $regPath) { Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue }
} catch {
    exit
}