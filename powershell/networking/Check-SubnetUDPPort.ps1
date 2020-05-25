param(
    [Parameter(Mandatory=$true)]
    [int[]] $udp_ports,
    [Parameter(Mandatory=$true)]
    [int] $ping_timeout_ms,
    [Parameter(Mandatory=$true)]
    [int] $udp_timeout_ms
)

# try each IP address in the subnet
0..255 | % {
    Write-Progress -Activity "Conducting test for UDP ports" -PercentComplete (($_ / 255) * 100)
    # generate the current IP address
    $ip_addr = "192.168.13.$_"
    # Check if the host can be reached - ping
    $result = ping -n 1 -w $ping_timeout_ms $ip_addr
    if ($result -match "ttl") {
        ForEach ($udp_port in $udp_ports) {
            # Set up the UDP client socket
            $udp_client = New-Object System.Net.Sockets.UdpClient
            $udp_client.Connect($ip_addr, $udp_port)
            $udp_client.Client.ReceiveTimeout = $udp_timeout_ms
            # Set up the message
            $ascii = New-Object System.Text.ASCIIEncoding
            $message_bytes = $ascii.GetBytes("TEST")
            # Send message and wait for reply
            [void]$udp_client.Send($message_bytes, $message_bytes.Length)
            $remote_endpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
            try {
                # Check if we received a reply from the remote host UDP port
                $receive_bytes = $udp_client.Receive([ref]$remote_endpoint)
                if ($receive_bytes) {
                    Write-Host "[OPEN] $ip_addr - UDP port $udp_port"
                }
            } Catch [System.Net.Sockets.SocketException] {
                # OPEN//filtered - check if host did not respond in time, but socket was not forcibly closed by remote
                if ($Error[0] -match "did not properly respond") {
                    Write-Host "[OPEN//filtered] $ip_addr - UDP port $udp_port"
                } else {
                    Write-Warning "$($Error[0])"
                }
            }
            # Close the UDP client, as it is no longer needed
            $udp_client.Close()
        }
    }
}
