$publicIP = (Invoke-RestMethod -Uri "https://ipecho.net/plain" -UseBasicParsing).Trim()

$localIP = @{
    connectionId = $p.connectionId
    status       = "Success"
    ip           = $publicIP
} | ConvertTo-Json -Compress

[System.IO.File]::WriteAllText("$($PSScriptRoot.Replace('\','\\'))\..\response_$($p.connectionId).json", $localIP)