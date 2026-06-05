$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json

$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.InterfaceAlias -notmatch "Loopback" -and
    $_.InterfaceAlias -notmatch "vEthernet" -and
    $_.IPAddress -notmatch "^169\."
} | Select-Object -First 1).IPAddress

$response = @{
    connectionId = $p.connectionId
    selected     = $localIP
} | ConvertTo-Json -Compress

$responsePath = Join-Path $PSScriptRoot "..\response_$($p.connectionId).json"
[System.IO.File]::WriteAllText((Resolve-Path $responsePath).Path, $response)