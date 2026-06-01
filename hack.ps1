# Parametre JSON dosyasını okuyoruz
$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json

# Dinamik Sistem Bilgileri
$localUser = $env:USERNAME
$computerName = $env:COMPUTERNAME
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "169.*" -and $_.IPAddress -notlike "127.*" }).IPAddress | Select-Object -First 1
if (-not $localIP) { $localIP = "192.168.1.$((Get-Random -Min 2 -Max 254))" }

# Ekran çözünürlüğünü alıyoruz
Add-Type -AssemblyName System.Windows.Forms
$screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height

# 1. SENARYO: Karmaşık Bellek Adresleri ve Kayıt Defteri Sızması (Hex kodları)
$scenario1 = @(
    "Write-Host '[*] Attaching debugger to lsass.exe Thread ID: $((Get-Random -Min 1000 -Max 5000))...' -ForegroundColor Cyan",
    "Write-Host '[-] NtReadVirtualMemory injected at memory offset: 0x00007FF7BB3E1000' -ForegroundColor Yellow",
    "Start-Sleep -Milliseconds 300",
    "Write-Host '`n[HEX DUMP - STACK POINTER]`' -ForegroundColor Magenta",
    "0..8 | ForEach-Object { Write-Host ('0x00007FF' + (Get-Random -Min 100 -Max 999) + ': ' + ((1..4 | ForEach-Object { (Get-Random -Min 10000000 -Max 99999999).ToString('X') }) -join ' ')) -ForegroundColor Green; Start-Sleep -Milliseconds 100 }",
    "Write-Host '`n[!] SAM Registry Hive decrypted successfully.' -ForegroundColor Red",
    "Write-Host '`n[LIVE COUNTER OBJECTS]`' -ForegroundColor Magenta; Get-Counter -ListSet * | Select-Object CounterSetName -First 5 | Out-String"
)

# 2. SENARYO: Matrix Efekti (0 ve 1'lerin hızlıca akması)
$scenario2 = @(
    "Write-Host '[*] Overriding system buffer... Initializing memory wipe stream...' -ForegroundColor Cyan",
    "Start-Sleep -Seconds 1",
    "0..40 | ForEach-Object { `$line = ''; 1..15 | ForEach-Object { `$line += (Get-Random -Min 0 -Max 2).ToString() + '  ' }; Write-Host `$line -ForegroundColor Green; Start-Sleep -Milliseconds 30 }",
    "Write-Host '`n[+] Memory buffer overflow triggered via CVE-2026-3192.' -ForegroundColor Red",
    "Write-Host '`n[ACTIVE SYSTEM DRIVERS]`' -ForegroundColor Magenta; Get-CimInstance Win32_SystemDriver | Select-Object Name, State -First 6 | Out-String"
)

# 3. SENARYO: Ağ Altyapısı Parçalama ve Şifrelenmiş Tünel
$scenario3 = @(
    "Write-Host '[*] Securing egress tunnel on local interface: $localIP...' -ForegroundColor Cyan",
    "Write-Host '[-] Routing traffic through proxy chain: 127.0.0.1 -> 185.220.101.$((Get-Random -Min 1 -Max 254))' -ForegroundColor Yellow",
    "0..10 | ForEach-Object { Write-Progress -Activity 'ESTABLISHING SSL VPN TUNNEL' -Status 'Exchanging Diffie-Hellman Keys...' -PercentComplete (`$_ * 10); Start-Sleep -Milliseconds 80 }",
    "Write-Host '[+] Tunnel Established. Cryptographic handshake: AES-256-GCM.' -ForegroundColor Green",
    "Write-Host '`n[ROUTING TABLE & METRICS]`' -ForegroundColor Magenta; Get-NetRoute | Select-Object DestinationPrefix, NextHop -First 5 | Out-String"
)

# 4. SENARYO: Derin Sistem Servisleri ve Arka Kapı Enjeksiyonu
$scenario4 = @(
    "Write-Host '[*] Intercepting RPC binding handles for user: $localUser...' -ForegroundColor Cyan",
    "Write-Host '[-] Modifying service descriptor DACL permissions...' -ForegroundColor Yellow",
    "Start-Sleep -Milliseconds 500",
    "Write-Host '[!] CRITICAL: Windows Defender real-time monitoring thread suspended.' -ForegroundColor Red",
    "Write-Host '`n[THREAD ANALYTICS]`' -ForegroundColor Magenta; Get-Process | Where-Object {`$_.Threads.Count -gt 50} | Select-Object Name, Id -First 5 | Out-String",
    "Write-Host '`n[+] System telemetry hijacked. Access maintained.' -ForegroundColor Green"
)

$scenarios = @($scenario1, $scenario2, $scenario3, $scenario4)
$titles = @("SYS_MUTEX_LOCK", "BINARY_BUFFER_STREAM", "CRYPT_TUNNEL_LOG", "CORE_SERVICE_HOOK")

# PARAMETRE KONTROLÜ
$cmdCount = if ($p.cmdCount) { $p.cmdCount } else { 4 }

for ($i = 0; $i -lt $cmdCount; $i++) {
    $scenarioIndex = $i % $scenarios.Count
    $currentScenario = $scenarios[$scenarioIndex]
    $currentTitle = $titles[$scenarioIndex]
    
    # Her pencere için tamamen rastgele X ve Y koordinatları
    $randX = Get-Random -Min 30 -Max ($screenWidth - 700)
    $randY = Get-Random -Min 30 -Max ($screenHeight - 500)
    $randWidth = Get-Random -Min 650 -Max 800
    $randHeight = Get-Random -Min 400 -Max 500
    
    # Komut dizisini güvenli hale getiriyoruz (Tırnak işaretlerini tamamen korumak için tek tırnak blokları kullandık)
    $scriptCommands = $currentScenario -join " ; Start-Sleep -Milliseconds $(Get-Random -Min 150 -Max 500); "
    
    # Windows API'sini (User32) PowerShell'in kendi iç mekanizmasıyla çağırıyoruz, tırnak karmaşası sıfıra iniyor
    $windowSetup = "[void][WindowPosition]::MoveWindow([WindowPosition]::GetConsoleWindow(), $randX, $randY, $randWidth, $randHeight, `$true)"
    
    # Yeni açılacak alt süreç için kurşun geçirmez script yapısı
    $finalCommand = "[console]::BackgroundColor = 'Black'; Clear-Host; " +
                    "Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class WindowPosition { [DllImport(\"user32.dll\")] public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint); [DllImport(\"kernel32.dll\")] public static extern IntPtr GetConsoleWindow(); }'; " +
                    "$windowSetup; " +
                    "$scriptCommands; " +
                    "Start-Sleep -Seconds 3; exit"

    # PowerShell'i base64 veya argüman karmaşasına sokmadan doğrudan en temiz scriptblock parametresiyle çağırıyoruz
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-Command", "title $($currentTitle)_$i; $finalCommand"
    
    # Pencerelerin patlama efekti gecikmesi
    Start-Sleep -Milliseconds (Get-Random -Min 200 -Max 500)
}