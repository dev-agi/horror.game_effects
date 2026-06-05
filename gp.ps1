$publicIP = (Invoke-RestMethod -Uri "https://ipecho.net/plain" -UseBasicParsing).Trim()

$response = @{
    connectionId        = $p.connectionId
    ip                  = $publicIP
} | ConvertTo-Json -Compress

$responsePath = Join-Path $PSScriptRoot "..\response_$($p.connectionId).json"
[System.IO.File]::WriteAllText((Resolve-Path $responsePath).Path, $response)