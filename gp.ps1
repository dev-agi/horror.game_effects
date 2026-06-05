$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json

$publicIP = (Invoke-RestMethod -Uri "https://ipecho.net/plain" -UseBasicParsing).Trim()

$response = @{
    connectionId = $p.connectionId
    status = "Success"
    selected = $publicIP
} | ConvertTo-Json -Compress

[System.IO.File]::WriteAllText("$PSScriptRoot\..\response_$($p.connectionId).json", $response)