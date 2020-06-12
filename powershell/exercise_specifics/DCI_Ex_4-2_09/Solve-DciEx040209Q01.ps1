param (
    [string[]] $file_list = "C:\Users\DCI Student\Desktop\ex_4-2_09\IOC_lists\files\ioc_files_2.txt",
    [string[]] $hash_list = "C:\Users\DCI Student\Desktop\ex_4-2_09\IOC_lists\files\fin4_hashes.txt"
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

# Read in the file list - each line is regex
$ioc_files = Get-Content -Path $file_list

# Read in the hash list
$ioc_hashes = @()
if ($hash_list -ne "") {
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
        # Expand environment variables and escape any backslash characters inserted by expansion of environment variables
        $ioc_files = $ioc_files | ForEach-Object { [System.Environment]::ExpandEnvironmentVariables($_) }  | ForEach-Object { $_ -replace "\\", "/" }
        # $ioc_files

        Get-ChildItem -Path "C:\" -Recurse -File -Force -ErrorAction SilentlyContinue | ? {
            # Check if filename matches an IOC file            
            ForEach ($ioc_file in $ioc_files) {
                if ($_.FullName -match $ioc_file) {
                    Write-Host "    -> Filepath match: $($_.FullName)"
                }
            }
            <#
            # Check file hashes against IOC hash list
            $hash = (Get-FileHash -Path $_.FullName -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
            if ($ioc_hashes -contains $hash) {
                Write-Host "    -> Hash match $($hash) - $($_.FullName)"
            }
            #>
        }
    }
}