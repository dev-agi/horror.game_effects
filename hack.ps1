# Parametre JSON dosyasını okuyoruz
$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json

# Dinamik Sistem Bilgilerini Çekiyoruz
$localUser = $env:USERNAME
$computerName = $env:COMPUTERNAME
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "169.*" -and $_.IPAddress -notlike "127.*" }).IPAddress | Select-Object -First 1
if (-not $localIP) { $localIP = "192.168.1.$((Get-Random -Min 2 -Max 254))" }

# 1. SENARYO: Ağ Tarama ve Port Sızma
$scenario1 = @(
    "Write-Host '[*] TARGET IDENTIFIED: $computerName ($localIP)' -ForegroundColor Cyan",
    "Write-Host '[*] Scanning subnet for open vectors...' -ForegroundColor Cyan",
    "Start-Sleep -Milliseconds 400",
    "Write-Host '[+] Port 445 [SMB] -> VULNERABLE (MS17-010 EternalBlue)' -ForegroundColor Green",
    "Write-Host '[+] Port 3389 [RDP] -> OPEN (Brute-force enabled)' -ForegroundColor Green",
    "Write-Host '[*] Deploying exploit payload via auxiliary/scanner/smb...'; Start-Sleep -Seconds 1",
    "Write-Host '[!] EXPLOIT SUCCESSFUL. SYSTEM PRIVILEGES GRANTED.' -ForegroundColor Red",
    "Write-Host '`n[LIVE NETWORK CONNECTIONS]`' -ForegroundColor Magenta; Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, RemoteAddress, State -First 7 | Out-String"
)

# 2. SENARYO: Kimlik Bilgileri ve LSASS Dump
$scenario2 = @(
    "Write-Host '[*] Accessing Local Security Authority Subsystem Service (LSASS)...' -ForegroundColor Cyan",
    "Write-Host '[*] Extracting SAM databases and active tokens...'; Start-Sleep -Milliseconds 800",
    "Write-Host '[!] WARNING: NTLM Hashes extracted successfully!' -ForegroundColor Yellow",
    "Write-Host '   [+] $computerName\\$localUser : 514da83b4ba4c52f631163a8a30d524e'",
    "Write-Host '   [+] Administrator : e21a37c95e6488d5dc7453488f725895'",
    "Write-Host '[*] Injecting persistence script into system services...'",
    "Write-Host '`n[RUNNING HOOKED PROCESSES]`' -ForegroundColor Magenta; Get-Process | Select-Object Name, Id, CPU -First 6 | Out-String"
)

# 3. SENARYO: Dosya Arama ve Veri Sızdırma (Exfiltration)
$scenario3 = @(
    "Write-Host '[*] Searching directory trees for high-value targets...' -ForegroundColor Cyan",
    "Write-Host '   -> Found: C:\Users\$localUser\Desktop\wallet.dat' -ForegroundColor Yellow",
    "Write-Host '   -> Found: C:\Users\$localUser\AppData\Roaming\Discord\tokens' -ForegroundColor Yellow",
    "0..10 | ForEach-Object { Write-Progress -Activity 'STAGING ENCRYPTED DATA' -Status 'Compressing payload...' -PercentComplete (`$_ * 10); Start-Sleep -Milliseconds 150 }",
    "Write-Host '[*] Establishing encrypted tunnel to C2 Server (185.220.101.$((Get-Random -Min 1 -Max 254)))...'",
    "0..10 | ForEach-Object { Write-Progress -Activity 'EXFILTRATING DATA' -Status 'Uploading via HTTPS Post...' -PercentComplete (`$_ * 10); Start-Sleep -Milliseconds 250 }",
    "Write-Host '[+] Exfiltration complete. 100% of target files cloned.' -ForegroundColor Green",
    "Write-Host '`n[LOCAL DRIVE PARTITIONS]`' -ForegroundColor Magenta; Get-Volume | Out-String"
)

# 4. SENARYO: İzleri Silme ve Kapanış
$scenario4 = @(
    "Write-Host '[*] Initiating anti-forensics clean-up protocol...' -ForegroundColor Cyan",
    "Write-Host '[!] Purging Windows Event Logs (Security)...' -ForegroundColor Yellow",
    "Write-Host '[!] Purging Windows Event Logs (System)...' -ForegroundColor Yellow",
    "Start-Sleep -Seconds 1",
    "Write-Host '[+] Event logs cleared. USN Journal wiped.' -ForegroundColor Green",
    "Write-Host '[+] Backdoor active on port $((Get-Random -Min 40000 -Max 65000)).'",
    "Write-Host '`n[!] DISCONNECTING REVERSE SHELL. ACCESS MAINTAINED.' -ForegroundColor Red"
)

# Tüm senaryoları ve başlıkları havuzda topluyoruz
$scenarios = @($scenario1, $scenario2, $scenario3, $scenario4)
$titles = @("KERNEL_EXPLOIT_STREAM", "CREDENTIAL_DUMP_SHELL", "DATA_EXFILTRATION_NODE", "ANTI_FORENSICS_WIPER")

# PARAMETRE KONTROLÜ: JSON'da cmdCount varsa onu kullan, yoksa varsayılan olarak 4 pencere aç
$cmdCount = if ($p.cmdCount) { $p.cmdCount } else { 4 }

for ($i = 0; $i -lt $cmdCount; $i++) {
    # Eğer cmdCount 4'ten büyükse senaryolar başa sararak (Modulus yardımıyla) tekrar dağıtılır
    $scenarioIndex = $i % $scenarios.Count
    $currentScenario = $scenarios[$scenarioIndex]
    $currentTitle = $titles[$scenarioIndex]
    
    # Çift tırnakları PowerShell argüman yapısına uygun şekilde kaçırıyoruz
    $escaped = $currentScenario | ForEach-Object { $_ -replace '"', '`"' }
    
    # Satırların arkasına insan yazma hızı efekti veren gecikmeler ekliyoruz
    $scriptCommands = $escaped | ForEach-Object { "$_ ; Start-Sleep -Milliseconds $(Get-Random -Min 350 -Max 900);" }
    
    # Terminali simsiyah yap, başlığı ata, komutları işlet ve işi bitince otomatik kapansın ('exit')
    $script = "title $($currentTitle)_$i; " +
              "[console]::BackgroundColor = 'Black'; Clear-Host; " +
              ($scriptCommands -join " ") + 
              "Start-Sleep -Seconds 2; exit"
              
    # Pencereyi fırlatıyoruz
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit -Command `"$script`""
    
    # Pencerelerin ardı ardına ekrana gelmesi için kaotik bir gecikme süresi
    Start-Sleep -Milliseconds (Get-Random -Min 300 -Max 700)
}