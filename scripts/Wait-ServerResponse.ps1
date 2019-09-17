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
    $TaskTimeoutSec,
    $RetryIntervalSec = 5
)

$timer = [Diagnostics.Stopwatch]::StartNew()

while (-not ($response.Headers.Server -match $HeaderString)) {

    if ($timer.Elapsed.TotalSeconds -gt $TaskTimeoutSec) {
        Write-Output "##vso[task.logissue type=error]Elapsed task time of [$($timer.Elapsed.TotalSeconds)] has exceeded timeout of [$TimeoutSeconds]"
        exit 1
    } else {
        Write-Output "##vso[task.logissue type=warning]Waiting for value [$HeaderString] in Response Headers Server...[$($timer.Elapsed.Minutes)m$($timer.Elapsed.Seconds)s elapsed]"
        $response = try {
            (Invoke-WebRequest -Method Get -Uri $DomainName -TimeoutSec $RequestTimeoutSec -ErrorAction Stop).BaseResponse
        } catch [System.Net.WebException] {
            Write-Verbose "An exception was caught: $($_.Exception.Message)"
            $_.Exception.Response
        }

        Start-Sleep -Seconds $RetryIntervalSec
    }
}

Write-Output "Found value [$HeaderString] in Response Headers Server - test succeeded"