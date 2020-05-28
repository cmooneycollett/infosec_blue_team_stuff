<#
.SYNOPSIS
    Checks the local system for IOC service names.
.DESCRIPTION
    Checks the local system for IOC service names. Input file must contain the
    list of service names to look for on the local system. The contents of the
    input file will typically be extracted from threat intelligence reporting
    relating to the particular APT or Threat Actor being searched for on the
    local machine.
.EXAMPLE
    PS C:\\> Check-IOCServiceNames.ps1 -in_file .\ioc_service_names.txt
    This syntax allows the script to check the local system for any services
    with a name included in the given list of IOC service names.
.INPUTS
    -in_file: list of IOC service names
.OUTPUTS
    Services with name matching an entry in the given IOC list. Following properties displayed:
    - Name
    - ProcessId
    - StartName
    - StartMode
    - State
    - PathName
#>
param (
    [Parameter(Mandatory=$true)]
    [string] $in_file
)
# Initialise array to hold IOC service names
$ioc_service_names = @{}
Get-Content -Path $in_file | ForEach-Object {
    $ioc_service_names.Add($_, $true)
}
# Look for services
Get-CimInstance Win32_Service | Where-Object {
    $ioc_service_names.ContainsKey($_.Name)
} | Select-Object -Property Name, ProcessId, StartName, StartMode, State, PathName | Format-Table
