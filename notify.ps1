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

    $xml = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text>$($p.title)</text>
            <text>$($p.text)</text>
            $([string]::IsNullOrEmpty($p.logo) ? "" : "<image placement=`"appLogoOverride`" src=`"$logoPath`"/>")
        </binding>
    </visual>
</toast>
"@

    $xmlDoc = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xmlDoc.LoadXml($xml)

    $appId = "Windows.SystemToast.Background"
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] | Out-Null
    $toast = [Windows.UI.Notifications.ToastNotification]::new($xmlDoc)

    $clicked = $false
    $startTime = Get-Date

    $activatedEvent = Register-ObjectEvent -InputObject $toast -EventName "Activated" -Action {
        $global:clicked = $true
    }

    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)

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
} catch {
    exit
}