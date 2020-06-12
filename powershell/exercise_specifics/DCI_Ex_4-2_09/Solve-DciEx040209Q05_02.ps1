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
$ioc_sched_tasks = @(
    "mim",
    "sekurlsa",
    "AT",
    "tmp"
)
# Prepare for remote connection
$trusted_hosts = $target_ips -join ","
Set-Item wsman:\localhost\client\trustedhosts -Value $trusted_hosts -Force

# Check each of the target machines
ForEach ($target_ip in $target_ips) {
    Write-Host -ForegroundColor Yellow "[?] Conducting interrogation of host $($target_ip)"
    Invoke-Command -ComputerName $target_ip -Credential $creds -ArgumentList $ioc_sched_tasks -ScriptBlock {
        param (
            [string[]] $ioc_sched_tasks
        )

        # Check which target machines have executed the "nbtscan.exe" utility
        Get-ScheduledTask | ? {$_.TaskName -in $ioc_sched_tasks}
    } 
}