param (
    [Parameter(Mandatory=$true)]
    [string] $cidr
)
# Initialise array of octet masks and results array
$octet_masks = (0, 128, 192, 224, 240, 248, 252, 254, 255)
$length = (256, 128, 64, 32, 16, 8, 4, 2, 1)
# Split CIDR to get the subnet mask length
$cidr_split = $cidr.Split("/")
if ($cidr_split.Length -ne 2) {
    throw "Bad CIDR format - bad number of '/' characters."
}
# Split subnet ID into octets
$cidr_octets = $cidr_split[0].Split(".")
if ($cidr_octets.Length -ne 4) {
    throw "Bad CIDR format - bad number of '.' characters."
}
# Determine which octet the subnet mask 1's end in and octet mask length
$first_var_octet = [int][Math]::Floor($cidr_split[1] / 8)
$var_octet_len = [int]($cidr_split[1] % 8)
# Combine standing octets into root of IP addresses in the range
$ip_root = ""
0..($first_var_octet - 1) | ForEach-Object {
    $ip_root += $cidr_octets[$_]
    $ip_root += "."
}
# for first variable octet:
# -> bitwise AND the CIDR octet with the octet mask
# -> count from resulting value up to and including 255
$first_val = $cidr_octets[$first_var_octet] -band $octet_masks[$var_octet_len]
$range_len = $length[$var_octet_len]
# Only count the first variable octet over the correct range length
$var_octet_vals = ($first_val..($first_val + $range_len - 1))
# Calculate total number of IPs to be generated and initialise result array size
$total_ips = [Math]::Pow(2, (32-$cidr_split[1]))
[string[]] $ip_addrs =  [string[]]::new($total_ips)
# count how many IP addresses generated, to allow result array indexing and progress report
$count = 0
ForEach ($val in $var_octet_vals) {
    # Combine IP address root and value for first variable octet
    $current_ip_addr = $ip_root
    $current_ip_addr += $val
    # for remaining variable octets:
    # -> count from 0 to 255 (inclusive)
    if ($first_var_octet -eq 3) {
        $ip_addrs[$count] = $current_ip_addr
        # Write progress
        $count += 1
        Write-Progress -Activity "Generating IP addresses" -PercentComplete (($count / $total_ips) * 100)
    } elseif ($first_var_octet -eq 2) {
        ForEach ($i in 0..255) {
            $ip_addrs[$count] = "$current_ip_addr.$i"
            # Write progress
            $count += 1
            Write-Progress -Activity "Generating IP addresses" -PercentComplete (($count / $total_ips) * 100)
        }
    } elseif ($first_var_octet -eq 1) {
        ForEach ($i in 0..255) {
            ForEach ($j in 0..255) {
                $ip_addrs[$count] = "$current_ip_addr.$i.$j"
                # Write progress
                $count += 1
                Write-Progress -Activity "Generating IP addresses" -PercentComplete (($count / $total_ips) * 100)
            }
        }
    } elseif ($first_var_octet -eq 0) {
        ForEach ($i in 0..255) {
            ForEach ($j in 0..255) {
                ForEach ($k in 0..255) {
                    $ip_addrs[$count] = "$current_ip_addr.$i.$j.$k"
                    # Write progress
                    $count += 1
                    Write-Progress -Activity "Generating IP addresses" -PercentComplete (($count / $total_ips) * 100)
                }
            }
        }
    }
}
# Display the list of IP addresses within the subnet described by given CIDR notation
return $ip_addrs
