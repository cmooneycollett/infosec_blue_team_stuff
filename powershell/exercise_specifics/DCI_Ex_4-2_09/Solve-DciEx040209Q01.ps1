param (
    [string[]] $file_lists,
    [string[]] $hash_list = @()
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


# Read in the file list
$ioc_files = @()
ForEach ($file_list in $file_lists) {
    $ioc_files += Get-Content -Path $file_list
}

# Read in the hash list
$ioc_hashes = @()
if ($hash_list.Length -gt 0) {
    $ioc_hashes = Get-Content -Path $hash_list
}

# Check each of the target machines
ForEach ($target_ip in $target_ips) {
    Write-Host -ForegroundColor Yellow "[?] Conducting interrogation of host $($target_ip)"
    Invoke-Command -ComputerName $target_ip -Credential $creds -ArgumentList $ioc_files,$ioc_hashes -ScriptBlock {
        param (
            [string[]] $ioc_files,
            [string[]] $ioc_hashes
        )

        # Expand any envars in the IOC files
        $ioc_files = $ioc_files | % { [System.Environment]::ExpandEnvironmentVariables($_) }

        # Find files with file path matching one of the IOC files
        $found_ioc_files = @()
        $found_ioc_files_hash = @()
        Get-ChildItem -Path "C:\" -Recurse -Force -ErrorAction SilentlyContinue | ? {
            $file = $_
            if (($null -ne ($ioc_files | ? {$_ -contains $file})) -eq $true) {
                $found_ioc_files += $file
            }
            <#
            $hash = (Get-FileHash -Path $file.FullName -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
            if ($ioc_hashes -contains $hash) {
                $found_ioc_files_hash += $hash
            }
            #>
        }

        $found_ioc_files
        Write-Host "##########"
        $found_ioc_files_hash


        # Stuff goes here
    }
}