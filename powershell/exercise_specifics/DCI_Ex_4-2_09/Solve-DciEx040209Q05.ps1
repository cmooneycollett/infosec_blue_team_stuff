# Grab credentials to connect to remote hosts with
$creds = Get-Credential

# Initialise target IPs
$target_ips = @(
    "172.16.12.7",
    "172.16.12.8",
    "172.16.12.9",
    "172.16.12.10",
    "172.16.12.11",
    "172.16.12.12",
    "172.16.12.13"
)
# Prepare for remote connection
$trusted_hosts = $target_ips -join ","
Set-Item wsman:\localhost\client\trustedhosts -Value $trusted_hosts -Force

# Check each of the target machines
ForEach ($target_ip in $target_ips) {
    Write-Host -ForegroundColor Yellow "[?] Conducting interrogation of host $($target_ip)"
    Invoke-Command -ComputerName $target_ip -Credential $creds -ScriptBlock {
        <#
        Get-CimInstance Win32_Process | Format-Table
        Get-CimInstance Win32_Service | Select-Object -Property Name, ProcessId, StartName, StartMode, State, PathName | Format-Table
        Get-EventLog -List
        #>

        Get-CimInstance Win32_StartupCommand | Select-Object Name,Command,User,Location | Format-Table

        # Check hosts file
        ###Get-Content -Path "C:\Windows\System32\Drivers\etc\hosts" | ? {$_.StartsWith("#") -eq $false}

        Write-Host "##########"

        # Check scheduled tasks
        ###Get-ScheduledTask | Format-Table -AutoSize

        # Check running processes

        # Check services
    } 
}