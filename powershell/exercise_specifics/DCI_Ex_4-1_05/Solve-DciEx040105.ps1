# 2. Read in IOC IP file
[System.Collections.Generic.HashSet[string]] $ioc_ips = Get-Content -Path ".\ips.txt"
# 3. Read in IOC Registry keys file
$ioc_reg = @()
Get-Content -Path ".\reg.txt" | % {
    $splits = $_.Split("\")
    $reg_key = ""
    ForEach ($i in 0..($splits.Length - 1)) {
        if ($i -eq ($splits.Length - 1)) {
            $reg_key += "#$($splits[$i])"
            if ($reg_key -match "HKEY_CURRENT_USER") {
                $reg_key = $reg_key -replace "HKEY_CURRENT_USER", "HKCU:"
            } elseif ($reg_key -match "HKEY_LOCAL_MACHINE") {
                $reg_key = $reg_key -replace "HKEY_LOCAL_MACHINE", "HKLM:"
            }
            $reg_key = $reg_key -replace """", ""
            $ioc_reg += $reg_key
        
        } elseif ($i -eq ($splits.Length - 2)) {
            $reg_key += "$($splits[$i])"
        } else {
            $reg_key += "$($splits[$i])\"
        }
    }
}
# 4. Read in IOC file list
$ioc_files = New-Object System.Collections.Generic.HashSet[String]]
Get-Content -Path ".\files.txt" | % {
    #$splits = $_.Split("\")
    #$ioc_files += $splits[$splits.Length - 1]
    $file = $_
    if ($file -match "%PROGRAMS%") {
        $file = $file -replace "%PROGRAMS%", "%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
    } elseif ($file -match "%USERAPPDATA%") {
        $file = $file -replace "%USERAPPDATA%", "%LOCALAPPDATA%"
    }
    $ioc_files += $file
}

# 1. Determine hosts on target network via ping scan
$alive_hosts = @("10.10.10.56","10.10.10.83","10.10.10.107")
$exclude_hosts = ("10.10.10.1", "10.10.10.20", "10.10.10.100") # Win10 Admin VM and Win10 NAS VM
Write-Output "[?] Conducting ping sweep of 10.10.10.0/24 subnet for host discovery ..."
<#
ForEach ($i in 1..254) {
    $ip_addr = "10.10.10.$($i)"
    $ping_result = ping -n 1 -w 1 $ip_addr
    if ($ping_result -match "Received = 1") {
        if ($exclude_hosts.Contains($ip_addr) -eq $false) {
            Write-Output "    -> Host alive - $($ip_addr)"
            $alive_hosts += $ip_addr
        } 
            Write-Output "    -> EXCLUDING: host alive - $($ip_addr)"
        }
    }
    Write-Progress -Activity "Conducting ping sweep of subnet..." -PercentComplete (($i / 254) * 100)
}
#>

# 0. Prepare for remote connections
Write-Output "[?] Preparing for remote connections ..."
$trusted_hosts = $alive_hosts -join ","
Set-Item wsman:\localhost\client\trustedhosts -Value $trusted_hosts -Force

#if ($creds -eq $null) {
    $creds = Get-Credential
#}

# 5. Connect to each of the alive hosts and scan
ForEach ($ip_addr in $alive_hosts) { 
    Write-Host "[?] Conducting interrogation of host $($ip_addr) ..."
    Invoke-Command -ComputerName $ip_addr -Credential $creds -ArgumentList $ioc_files,$ioc_ips,$ioc_reg -ScriptBlock {
        param (
            [System.Collections.Generic.HashSet[string]] $ioc_files,
            [System.Collections.Generic.HashSet[string]] $ioc_ips,
            [string[]] $ioc_reg
        )
        # a) Check if any of the IOC files are present on the system
        <#
        Get-ChildItem -Path "C:\" -Recurse -Force -ErrorAction SilentlyContinue -Exclude "*.lnk" | % {
            if ($ioc_files.Contains($_.Name)) {
                Write-Host "    -> Found possible IOC file: $($_.FullName)"
            }
        }
        #>
        ForEach ($file in $ioc_files) {
            $file = [System.Environment]::ExpandEnvironmentVariables($file)
            $result = Test-Path -Path $file
            if ($result -eq $true) {
                Write-Host "    -> Found IOC file: $($file)"
            }
        }
        # b) Check if any of the IOC Registry values are present on the system
        ForEach ($reg in $ioc_reg) {
            $splits = $reg.Split("#")
            $key = $splits[0]
            $value = $splits[1]
            # Get the reg value if it exists
            $reg_result = Get-ItemProperty -Path $key -Name $value -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $value
            if ($reg_result.Length -gt 0) {
                Write-Host "    -> Found IOC reg: $($key), ""$($value)"""
                Write-Host "       => $($reg_result)"
            }
        }
        # c) Check if system has any established TCP connections to an IOC IP address
        Get-NetTCPConnection | % {
            $remote_ip = $_.RemoteAddress
            if ($ioc_ips.Contains($remote_ip)) {
                Write-Host "    -> Found IP IOC: $($remote_ip)"
                $_ | Format-List
            }
        }
    }
}




