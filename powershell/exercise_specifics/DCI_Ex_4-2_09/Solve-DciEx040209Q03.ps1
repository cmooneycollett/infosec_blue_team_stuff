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
        $ioc_dns = (
            "ctable.com",
            "nestlere.com",
            "unina2.net",
            "shwoo.gov",
            "msa.hinet.net",
            "news.rinpocheinfo.com",
            "ellismikepage.info",
            "lifehealthsanfrancisco2015.com",
            "pgallerynow.info",
            "dmforever.biz",
            "msoutexchange.us",
            "junomaat81.us",
            "outlookscansafe.net",
            "nickgoodsite.co.uk",
            "uae.kim",
            "updato.systes.net",
            "removalmalware.servecounterstrike.com",
            "mailchat.zapto.org",
            "outlookexchange.net"
        )
        $ioc_ip = (
            "98.139.183.183",
            "11.76.174.166",
            "123.125.114.144",
            "84.246.78.212",
            "128.107.176.140",
            "178.105.226.163",
            "148.212.247.185",
            "201.70.116.57",
            "93.212.59.21",
            "93.212.59.28"
        )


        $results = Get-DnsClientCache | ? {$ioc_dns.Contains($_.Entry) -or $ioc_ip.Contains($_.Data)}
        # $results | Format-List
        Get-Content -Path "C:\Windows\System32\Drivers\etc\hosts"


        # Stuff goes here
    } # | Set-Content -Path ".\$($target_ip)_Q2.txt"
}