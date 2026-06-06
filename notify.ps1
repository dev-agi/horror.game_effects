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

    $xml = New-Object System.Text.StringBuilder
    [void]$xml.Append("<toast><visual><binding template='ToastGeneric'>")
    [void]$xml.Append("<text>$($p.title)</text>")
    [void]$xml.Append("<text>$($p.text)</text>")
    if (Test-Path $logoPath) {
        [void]$xml.Append("<image placement='appLogoOverride' src='$logoPath'/>")
    }
    [void]$xml.Append("</binding></visual></toast>")

    $xmlDoc = New-Object -ComObject Microsoft.XMLDOM
    [void]$xmlDoc.loadXML($xml.ToString())

    $wscript = New-Object -ComObject WScript.Shell
    $regPath = "HKCU\SOFTWARE\Classes\AppId\PowershellNotification"
    $wscript.RegWrite("$regPath\", "PowershellNotification", "REG_SZ")
    $wscript.RegWrite("$regPath\ShowInActionCenter", 1, "REG_DWORD")

    $asTask = [PowerShell]::Create().AddScript({
        param($xmlString, $time, $connectionId, $pRoot)
        try {
            [void][System.Reflection.Assembly]::LoadWithPartialName("System.Runtime.InteropServices.WindowsRuntime")
            
            $xmlDoc = New-Object Windows.Data.Xml.Dom.XmlDocument
            $xmlDoc.LoadXml($xmlString)
            
            $toast = [Windows.UI.Notifications.ToastNotification]::new($xmlDoc)
            $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("PowershellNotification")
            
            $clicked = $false
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            
            $activated = Register-ObjectEvent -InputObject $toast -EventName "Activated" -Action { $global:clicked = $true }
            
            $notifier.Show($toast)
            
            while ($timer.Elapsed.TotalSeconds -lt $time -and -not $global:clicked) {
                Start-Sleep -Milliseconds 50
            }
            
            if ($global:clicked) {
                @{ connectionId = $connectionId; answer = "clicked" } | ConvertTo-Json -Compress | Set-Content "$pRoot\..\response_$($connectionId).json" -Encoding UTF8
            }
            
            Unregister-Event -SourceIdentifier $activated.Name -ErrorAction SilentlyContinue
        } catch {}
    }).AddArgument($xml.ToString()).AddArgument($p.time).AddArgument($p.connectionId).AddArgument($PSScriptRoot)
    
    $job = $asTask.BeginInvoke()
    
    $mainTimer = [System.Diagnostics.Stopwatch]::StartNew()
    while (-not $job.IsCompleted -and $mainTimer.Elapsed.TotalSeconds -lt ($p.time + 2)) {
        Start-Sleep -Milliseconds 100
    }

    $asTask.Dispose()
    if (Test-Path $logoPath) { Remove-Item $logoPath -Force -ErrorAction SilentlyContinue }
} catch {
    exit
}