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
        <#
        Get-Process | Select-Object -Property Name, Id, Path | Format-Table
        Get-CimInstance Win32_Service | Select-Object -Property Name, ProcessId, StartName, StartMode, State, PathName | Format-Table
        Get-ScheduledTask | Format-Table
        #>

        # Check Run* keys on the target machine
        $run_key_paths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunServices",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunServicesOnce",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Run",
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\RunOnce",
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\RunServices",
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\RunServicesOnce",
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Policies\Explorer\Run",
            "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Run",
            "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\RunOnce"
        )
        # Check each of the run keys
        ForEach ($run_key_path in $run_key_paths) {
            # Check if the key is not present - go to next path if so
            if (!(Test-Path -Path $run_key_path)) {
                continue
            }
            # Get the contents of the key - exclude properties introduced by Powershell
            $run_key = Get-ItemProperty -Path $run_key_path | 
                Select-Object * -exclude PSPath, PSParentPath, PSChildName, PSDrive, PSProvider
            # Check if there are any subkeys or values within the Run key
            if (($run_key | Measure-Object).Count -eq 0) {
                continue
            }
            Write-Output $run_key_path
            Write-Output $run_key | Format-List
        }
        # Check the "C:\tmp" directory for other files that may have been created or downloaded by the adversary
        Get-ChildItem -Path "C:\tmp" -ErrorAction SilentlyContinue | Format-Table -AutoSize
    }
}