# Create list of registry Run* subkeys
$run_key_paths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunServices",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunServicesOnce",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
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
    $run_key | Format-List
}
