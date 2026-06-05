$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json

$localIP = ([System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).AddressList | Where-Object { $_.AddressFamily -eq "InterNetwork" } | Select-Object -First 1).IPAddressToString

$response = @{
    connectionId = $p.connectionId
    status = "Success"
    selected = $localIP
} | ConvertTo-Json -Compress

[System.IO.File]::WriteAllText("$PSScriptRoot\..\response_$($p.connectionId).json", $response)