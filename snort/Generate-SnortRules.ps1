param (
    [string] $apt_name = "fsociety",
    [string] $ioc_ip_file = "",
    [string] $ioc_domain_file = "",
    [string] $ioc_http_req_file = ""
)

# Initialise alert SID
$sid = 1000001

# Print out ICMP test rule
Write-Output "# Test rules"
Write-Output "# alert icmp any any <> any any (msg:""ICMP Test""; sid: $($sid);)"
Write-Output ""
$sid += 1

# Snort alerts for IP addresses
if ($ioc_ip_file -ne "") {
    # Read in the file
    $ioc_ip_lines = Get-Content -Path $ioc_ip_file
    Write-Output "# Rules for $($apt_name) IOCs - IP addresses"
    ForEach ($line in $ioc_ip_lines) {
        # Trim any leading or trailing whitespace, then ignore any empty lines
        $line = $line.Trim()
        if ($line.Length -eq 0) {
            continue
        }
        Write-Output "alert ip any any <> $($line) any (msg:""BADNESS - Detected $($apt_name) IOC - IP addr - $($line)""; sid: $($sid);)"
        $sid += 1
    }
    Write-Output ""
}

# Snort alerts for domain names
if ($ioc_domain_file -ne "") {
    # Read in the file
    $ioc_domain_lines = Get-Content -Path $ioc_domain_file
    Write-Output "# Rules for $($apt_name) IOCs - domains"
    ForEach ($line in $ioc_domain_lines) {
        # Trim any leading and training whitespace, then ignore any empty lines
        $line = $line.Trim()
        if ($line.Length -eq 0) {
            continue
        }
        $elements = $line.Split(".")
        $content = ""
        ForEach ($elem in $elements) {
            # Ignore blank elements
            if ($elem.Length -eq 0) {
                continue
            }
            $content += "content:""$($elem)""; "
        }
        Write-Output "alert udp any any -> any any (msg:""BADNESS - Detected $($apt_name) IOC - Domain name - $($line)""; $($content)sid: $($sid);)"
        $sid += 1
    }
    Write-Output ""
}

# Snort alerts for HTTP requests (GET and POST)
if ($ioc_http_req_file -ne "") {
    $ioc_http_req_lines = Get-Content -Path $ioc_http_req_file
    Write-Output "# Rules for $($apt_name) IOCs - HTTP requests (GET and POST)"
    ForEach ($line in $ioc_http_req_lines) {
        # Trim any leading or trailing whitespace, then ignore any empty lines
        $line = $line.Trim()
        if ($line.Length -eq 0) {
            continue
        }
        # Generate sequence of content statements to match HTTP request packet
        $elements = $line.Replace("/", ".").Split(".")
        $content_http_get = "content:""GET""; http_method;"
        $content_http_post = "content:""POST""; http_method;"
        ForEach ($elem in $elements) {
            $content_http_get += " content:""$($elem)"";"
            $content_http_post += " content:""$($elem)"";"
        }
        # Leave port spec as wildcard, so we catch HTTP requests going to atypical
        # ports (i.e. not TCP 80)
        Write-Output("alert tcp any any -> any any (msg:""BADNESS - Detected $($apt_name) IOC - HTTP GET for file $($line)""; $($content_http_get) sid: $($sid);)")
        $sid += 1
        Write-Output("alert tcp any any -> any any (msg:""BADNESS - Detected $($apt_name) IOC - HTTP POST for file $($line)""; $($content_http_post) sid: $($sid);)")
        $sid += 1
    }
    Write-Output ""
}

# Finished printing out Snort rules
Write-Output "# END OF RULES"
