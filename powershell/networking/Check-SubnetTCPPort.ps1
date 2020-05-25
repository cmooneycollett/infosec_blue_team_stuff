param(
    [Parameter(Mandatory=$true)]
    [int[]] $tcp_ports,
    [Parameter(Mandatory=$true)]
    [int] $ping_timeout_ms
)

# try each IP address in the subnet
0..255 | % {
    Write-Progress -Activity "Conducting connection test for TCP ports" -PercentComplete (($_ / 255) * 100)
    # generate the current IP address
    $ip_addr = "192.168.13.$_"
    # Check if the host can be reached - ping
    $result = ping -n 1 -w $ping_timeout_ms $ip_addr
    # Check if host is reachable, then check connectivity to each TCP specified
    if ($result -match "ttl") {
        ForEach ($tcp_port in $tcp_ports) {
            Test-NetConnection -Port $tcp_port -InformationLevel Detailed $ip_addr | ? {$_.TcpTestSucceeded -eq "True"}
        }
    }
}
