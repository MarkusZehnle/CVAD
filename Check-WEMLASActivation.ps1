<#
.SYNOPSIS
    Checks Citrix WEM Infrastructure Service licensing events, but only if Debug Mode is enabled.

.DESCRIPTION
    This script verifies whether Debug Mode for the Citrix WEM Infrastructure Broker Service
    is enabled by reading the registry value (REG_DWORD):

        HKLM\SYSTEM\CurrentControlSet\Control\Norskale\Infrastructure Services\BrokerServiceDebugMode

    Debug logging is required for detailed licensing-related WEM events.
    Enabling Debug Mode will restart the Citrix WEM Infrastructure Service
    and produces verbose (chatty) logging.

    If Debug Mode is enabled, the script queries the
    "WEM Infrastructure Service" event log and returns the 5 most recent
    licensing-related entries matching a defined message pattern.

    If Debug Mode is not enabled, the script exits with a warning and
    provides instructions on how to enable Debug Mode.

    Possible event log messages you could check for include:
      (1) "LICENSING: LS returned LAS Activation for WEM with expiration m/dd/yyyy"
      (2) "LICENSING: LS indicates WEM is LAS Activated. Activation expires on m/dd/yyyy"
      (3) "Finish to check activation from Citrix Licensing Service(Web), license valid: True"
      (4) "LICENSING: LS returned activation list with x entries" (x = number)

    Not specific to LAS but licensing in general:
      "License server connection successful [hostname.domain.tld:27000]"

.VERSION
    1.0 / 2026.01.21 / markus.zehnle@braincon.de
        - Initial creation

.EXAMPLE
    PS C:\> .\Check-WEMLASActivation.ps1

    Checks whether WEM Debug Mode is enabled and, if so, outputs the
    five most recent LAS licensing-related event log entries.
#>


# Message pattern to check
$messageToCheckFor = 'LICENSING: LS indicates WEM is LAS Activated.*'

# Registry path for WEM Debug Mode
$RegPath  = 'HKLM:\SYSTEM\CurrentControlSet\Control\Norskale\Infrastructure Services'
$RegValue = 'BrokerServiceDebugMode'

# How many entries you wanna see?
$numberOfEntriesToReturn = 5

# Check Debug Mode
try {
    $DebugMode = Get-ItemPropertyValue -Path $RegPath -Name $RegValue -ErrorAction Stop
}
catch {
    Write-Warning "Unable to determine WEM Infrastructure Service Debug Mode (registry value not found)."
    return
}

if ($DebugMode -ne 1) {
    Write-Warning @"
WEM Infrastructure Service Debug Mode is NOT enabled.

To enable debug mode:
 1. Start 'WEM Infrastructure Service Configuration'
 2. Go to the 'Advanced Settings' tab
 3. Check 'Enable debug mode'
 4. Click 'Save Configuration'

Attention: Citrix WEM Infrastructure Service restarts and debug mode is chatty! ;)
"@
    return
}

Write-Host "WEM Infrastructure Service Debug Mode is ENABLED. Checking event log entries..." -ForegroundColor Green

# Query eventlog and return only the $numberOfEntriesToReturn most recent entries
$events = Get-WinEvent -FilterHashtable @{
    LogName = 'WEM Infrastructure Service'
} | Where-Object {
    $_.Message -like $messageToCheckFor
} | Sort-Object TimeCreated -Descending |
Select-Object -First $numberOfEntriesToReturn TimeCreated, Id, LevelDisplayName, Message

$events
