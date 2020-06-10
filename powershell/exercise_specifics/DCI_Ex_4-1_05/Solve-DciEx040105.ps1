# Get the credentials to connect to any remotes with - so script is set and forget after this
$creds = Get-Credential

# Read in IOC IP file
[System.Collections.Generic.HashSet[string]] $ioc_ips = Get-Content -Path ".\ips.txt"

# Read in IOC Registry keys file
$ioc_reg = @()
Get-Content -Path ".\reg.txt" | ForEach-Object {
    $splits = $_.Split("\")
    $reg_key = ""
    ForEach ($i in 0..($splits.Length - 1)) {
        if ($i -eq ($splits.Length - 1)) {
            # Set up IOC registry strings so they are interpreted as registry paths
            if ($reg_key -match "HKEY_CURRENT_USER") {
                $reg_key = $reg_key -replace "HKEY_CURRENT_USER", "HKCU:"
            } elseif ($reg_key -match "HKEY_LOCAL_MACHINE") {
                $reg_key = $reg_key -replace "HKEY_LOCAL_MACHINE", "HKLM:"
            }
            $ioc_reg += [System.Tuple]::Create($reg_key, ($splits[$i] -replace """", ""))
        } else {
            $reg_key += "$($splits[$i])\"
        }
    }
}

# Read in IOC file list
$ioc_files = New-Object System.Collections.Generic.HashSet[String]]
Get-Content -Path ".\files.txt" | ForEach-Object {
    $file = $_
    # Replace any of the problematic envars with ones that will expand correctly on remotes
    if ($file -match "%PROGRAMS%") {
        $file = $file -replace "%PROGRAMS%", "%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
    } elseif ($file -match "%USERAPPDATA%") {
        $file = $file -replace "%USERAPPDATA%", "%APPDATA%"
    }
    $ioc_files += $file
}

# Determine hosts on target network via ping scan
$exclude_hosts = @("10.10.10.1", "10.10.10.20", "10.10.10.100") # Win10 Admin VM and Win10 NAS VM
Write-Host -ForegroundColor Yellow "[?] Conducting ping sweep of 10.10.10.0/24 subnet for host discovery ..."
workflow ParallelPingSweep (
    [string[]] $ioc_ips,
    [string[]] $exclude_hosts
) {
    # Hide the workflow progress bar
    $ProgressPreference = "SilentlyContinue"
    # Conduct ping sweep in parallel, max. 50 pings concurrently
    ForEach -Parallel -ThrottleLimit 50 ($i in 1..254) {
        $ip_addr = "10.10.10.$($i)"
        # Ping the target once and check if a reply was received
        $ping_result = ping -n 1 -w 1 $ip_addr
        if ($ping_result -match "Received = 1") {
            if (!($exclude_hosts.Contains($ip_addr))) {
                InlineScript { Write-Host "    -> Host alive - $($Using:ip_addr)" }
                $ip_addr
            } else {
                InlineScript { Write-Host "    -> EXCLUDING: Host alive - $($Using:ip_addr)" }
            }
        }
    }
}
$alive_hosts = ParallelPingSweep -ioc_ips $ioc_ips -exclude_hosts $exclude_hosts

# Prepare for remote connections
Write-Host -ForegroundColor Yellow "[?] Preparing for remote connections ..."
$trusted_hosts = $alive_hosts -join ","
Set-Item wsman:\localhost\client\trustedhosts -Value $trusted_hosts -Force

# Connect to each of the alive hosts and scan
ForEach ($ip_addr in $alive_hosts) { 
    Write-Host -ForegroundColor Yellow "[?] Conducting interrogation of host $($ip_addr) ..."
    Invoke-Command -ComputerName $ip_addr -Credential $creds -ArgumentList $ioc_files,$ioc_ips,$ioc_reg -ScriptBlock {
        param (
            [System.Collections.Generic.HashSet[string]] $ioc_files,
            [System.Collections.Generic.HashSet[string]] $ioc_ips,
            [Object[]] $ioc_reg
        )

        # Check if any of the IOC files are present on the system
        ForEach ($file in $ioc_files) {
            $file = [System.Environment]::ExpandEnvironmentVariables($file)
            $result = Test-Path -Path $file
            if ($result -eq $true) {
                Write-Host -ForegroundColor Red "    -> Found IOC file: $($file)"
            }
        }

        # Check if any of the IOC Registry values are present on the system
        ForEach ($reg in $ioc_reg) {
            $key_name = $reg.Item1
            $value_name = $reg.Item2
            # Get the reg value if it exists
            $value_proper = Get-ItemProperty -Path $key_name -Name $value_name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $value_name
            if ($value_proper.Length -gt 0) {
                Write-Host -ForegroundColor Red "    -> Found IOC reg: $($key_name), ""$($value_name)"""
                Write-Host "       => $($value_proper)"
            }
        }

        # Check if system has any established TCP connections to an IOC IP address
        Get-NetTCPConnection | ForEach-Object {
            $remote_ip = $_.RemoteAddress
            if ($ioc_ips.Contains($remote_ip)) {
                Write-Host -ForegroundColor Red "    -> Found IP IOC: $($remote_ip)"
                $_ | Format-List
            }
        }
    }
}
