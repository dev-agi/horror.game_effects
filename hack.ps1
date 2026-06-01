# Parametre JSON dosyasını okuyoruz
$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json

# Dinamik Sistem Bilgileri
$localUser = $env:USERNAME
$computerName = $env:COMPUTERNAME
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "169.*" -and $_.IPAddress -notlike "127.*" }).IPAddress | Select-Object -First 1
if (-not $localIP) { $localIP = "192.168.1.$((Get-Random -Min 2 -Max 254))" }

# Ekran boyutlarını alıyoruz
$wmiScreen = Get-CimInstance Win32_VideoController
$screenWidth = if ($wmiScreen.CurrentHorizontalResolution) { $wmiScreen.CurrentHorizontalResolution } else { 1920 }
$screenHeight = if ($wmiScreen.CurrentVerticalResolution) { $wmiScreen.CurrentVerticalResolution } else { 1080 }

# SENARYOLAR
$scenario1 = @(
    "Write-Host '[*] Attaching debugger to lsass.exe Thread ID: $((Get-Random -Min 1000 -Max 5000))...' -ForegroundColor Cyan",
    "Write-Host '[-] NtReadVirtualMemory injected at memory offset: 0x00007FF7BB3E1000' -ForegroundColor Yellow",
    "Write-Host '`n[HEX DUMP - STACK POINTER]`' -ForegroundColor Magenta",
    "0..12 | ForEach-Object { Write-Host ('0x00007FF' + (Get-Random -Min 100 -Max 999) + ':  A8 4F 33 ' + (Get-Random -Min 10 -Max 99) + ' EE FF ' + (Get-Random -Min 1000 -Max 9999)) -ForegroundColor Green; Start-Sleep -Milliseconds 30 }",
    "Write-Host '`n[!] SAM Registry Hive decrypted successfully.' -ForegroundColor Red",
    "Write-Host '`n[LIVE SYSTEM SERVICES]`' -ForegroundColor Magenta; Get-Service | Where-Object {`$_.Status -eq 'Running'} | Select-Object Name -First 8 | Out-String"
)

$scenario2 = @(
    "Write-Host '[*] Overriding system buffer... Initializing memory wipe stream...' -ForegroundColor Cyan",
    "0..60 | ForEach-Object { `$line = ''; 1..20 | ForEach-Object { `$line += (Get-Random -Min 0 -Max 2).ToString() + ' ' }; Write-Host `$line -ForegroundColor Green; Start-Sleep -Milliseconds 15 }",
    "Write-Host '`n[+] Memory buffer overflow triggered via CVE-2026-3192.' -ForegroundColor Red",
    "Write-Host '`n[ACTIVE SYSTEM DRIVERS]`' -ForegroundColor Magenta; Get-CimInstance Win32_SystemDriver | Select-Object Name, State -First 8 | Out-String"
)

$scenario3 = @(
    "Write-Host '[*] Securing egress tunnel on local interface: $localIP...' -ForegroundColor Cyan",
    "Write-Host '[-] Routing traffic through proxy chain: 127.0.0.1 -> 185.220.101.$((Get-Random -Min 1 -Max 254))' -ForegroundColor Yellow",
    "0..10 | ForEach-Object { Write-Progress -Activity 'ESTABLISHING SSL VPN TUNNEL' -Status 'Exchanging Diffie-Hellman Keys...' -PercentComplete (`$_ * 10); Start-Sleep -Milliseconds 40 }",
    "Write-Host '[+] Tunnel Established. Cryptographic handshake: AES-256-GCM.' -ForegroundColor Green",
    "Write-Host '`n[ROUTING TABLE & METRICS]`' -ForegroundColor Magenta; Get-NetRoute | Select-Object DestinationPrefix, NextHop -First 7 | Out-String"
)

$scenario4 = @(
    "Write-Host '[*] Intercepting RPC binding handles for user: $localUser...' -ForegroundColor Cyan",
    "Write-Host '[-] Modifying service descriptor DACL permissions...' -ForegroundColor Yellow",
    "Write-Host '[!] CRITICAL: Windows Defender real-time monitoring thread suspended.' -ForegroundColor Red",
    "Write-Host '`n[THREAD ANALYTICS]`' -ForegroundColor Magenta; Get-Process | Where-Object {`$_.Threads.Count -gt 50} | Select-Object Name, Id -First 8 | Out-String",
    "Write-Host '`n[+] System telemetry hijacked. Access maintained.' -ForegroundColor Green"
)

$scenarios = @($scenario1, $scenario2, $scenario3, $scenario4)
$titles = @("SYS_MUTEX_LOCK", "BINARY_BUFFER_STREAM", "CRYPT_TUNNEL_LOG", "CORE_SERVICE_HOOK")

# PARAMETRE KONTROLÜ
$cmdCount = if ($p.cmdCount) { $p.cmdCount } else { 4 }

# Grid boyutları
$wWidth = 650
$wHeight = 400
$cols = [Math]::Max(1, [Math]::Floor($screenWidth / $wWidth))

for ($i = 0; $i -lt $cmdCount; $i++) {
    $scenarioIndex = $i % $scenarios.Count
    $currentScenario = $scenarios[$scenarioIndex]
    $currentTitle = $titles[$scenarioIndex]
    
    # Grid algoritması (Üst üste binmeyi engeller)
    $row = [Math]::Floor($i / $cols)
    $col = $i % $cols
    
    $posX = ($col * $wWidth) + (Get-Random -Min -20 -Max 40)
    $posY = ($row * $wHeight) + (Get-Random -Min -20 -Max 40)
    
    if ($posX -gt ($screenWidth - $wWidth)) { $posX = Get-Random -Min 0 -Max 200 }
    if ($posY -gt ($screenHeight - $wHeight)) { $posY = Get-Random -Min 0 -Max 200 }

    $scriptCommands = $currentScenario -join " ; Start-Sleep -Milliseconds $(Get-Random -Min 80 -Max 250); "
    
    # Yeni açılacak temiz alt kod bloğu (Artık tırnak kaçırma derdi yok!)
    $subScript = @"
[console]::BackgroundColor = 'Black'
Clear-Host
`$host.UI.RawUI.WindowTitle = '$($currentTitle)_$i'
`$code = 'using System; using System.Runtime.InteropServices; public class WinAPI { [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags); [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow(); }'
Add-Type -TypeDefinition `$code
[WinAPI]::SetWindowPos([WinAPI]::GetConsoleWindow(), 0, $posX, $posY, 0, 0, 0x0001)
$scriptCommands
Start-Sleep -Seconds 3
exit
"@

    # Kodu hatasız iletmek için Base64 formatına çeviriyoruz
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($subScript)
    $encodedCode = [Convert]::ToBase64String($bytes)

    # PowerShell'i şifreli/güvenli komutla başlatıyoruz (Hata ihtimali %0)
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-EncodedCommand", $encodedCode
}