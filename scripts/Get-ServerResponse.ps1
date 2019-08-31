<#
.SYNOPSIS
    Looks for specific string in Server Response Header on given Uri
.DESCRIPTION
    Looks for specific string in Server Response Header on given Uri using Invoke-WebRequest
.LINK
    https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest?view=powershell-6
.NOTES
    Author:  Steve Baker
    Blog:    https://steevaavoo.github.io
    GitHub:  https://github.com/steevaavoo
    Twitter: @SteveBa89047651
#>

[CmdletBinding()]
param (
    $DomainName,
    $HeaderString,
    $RequestTimeoutSec,
    $TaskTimeoutSec
)

$response = $null
while (-not ($response.Headers.Server -eq $HeaderString)) {
    Write-Output "Waiting for value [$HeaderString] in Response Headers Server..."
    $response = Invoke-WebRequest -Method Get -Uri $DomainName -TimeoutSec $RequestTimeoutSec
}
Write-Output "Found value [$HeaderString] in Response Headers Server - test succeeded"