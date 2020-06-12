param (
    [string] $ioc_domains_file = "C:\Users\DCI Student\Desktop\ex_4-2_09\IOC_lists\files\ioc_domains.txt",
    [string] $ioc_ips_file = "C:\Users\DCI Student\Desktop\ex_4-2_09\IOC_lists\files\ioc_ips.txt",
    [string] $ioc_hosts_entries_file = "C:\Users\DCI Student\Desktop\ex_4-2_09\IOC_lists\files\ioc_hosts.txt"
)

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

# Read in IOC lists - domain names and IP addresses
$ioc_domains = Get-Content -Path $ioc_domains_file
$ioc_ips = Get-Content -Path $ioc_ips_file
$ioc_hosts_entries = Get-Content -Path $ioc_hosts_entries_file | % {$_ -replace "\s+", " "}

# Check each of the target machines
ForEach ($target_ip in $target_ips) {
    Write-Host -ForegroundColor Yellow "[?] Conducting interrogation of host $($target_ip)"
    Invoke-Command -ComputerName $target_ip -Credential $creds -ArgumentList $ioc_domains,$ioc_ips,$ioc_hosts_entries -ScriptBlock {
        param (
            [string[]] $ioc_domains,
            [string[]] $ioc_ips,
            [string[]] $ioc_hosts_entries
        )
        # Get contents of the DNS client cache with a IP address or domain name matching an ioc
        Write-Host "##### DNS Client Cache matches"
        $results = Get-DnsClientCache | ? {$ioc_domains.Contains($_.Entry) -or $ioc_ips.Contains($_.Entry) -or $ioc_domains.Contains($_.Data) -or $ioc_ips.Contains($_.Data)}
        $results | Format-Table -AutoSize
        Write-Host ""

        # Check remote address for any network connections against IOC IP addresses
        Write-Host "##### Network connection matches"
        Get-NetTCPConnection | ? {
            $ioc_ips.Contains($_.RemoteAddress)
        }
        Write-Host ""

        # Get entries from hosts file
        Write-Host "##### Hosts file matches"

        Get-Content -Path "C:\Windows\System32\Drivers\etc\hosts" | ? {$_.StartsWith("#") -eq $false} | % {$_ -replace "\s+", " "} | % {
            ForEach ($ioc_hosts_entry in $ioc_hosts_entries) {
                if ($_ -match $ioc_hosts_entry) {
                    Write-Host "     -> Hosts entry match: $($_)"
                }
            }
            ForEach ($ioc_ip in $ioc_ips) {
                if ($_ -match $ioc_ip) {
                    Write-Host "     -> Hosts entry match (IP): $($_)"
                }
            }
            ForEach ($ioc_domain in $ioc_domains) {
                if ($_ -match $ioc_domain) {
                    Write-Host "     -> Hosts entry match (domain): $($_)"
                }
            }
        }
        Write-Host ""
    }
}