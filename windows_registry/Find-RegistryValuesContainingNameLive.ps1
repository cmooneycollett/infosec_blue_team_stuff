param (
    [Parameter(Mandatory=$true)]
    [string] $in_file
)
# Open the in-file and read into list
$target_names = Get-Content -Path $in_file
# Initialise registry roots
$reg_roots = (
    "HKCU:\",
    "HKLM:\",
    "HKU:\"
)
# Recurse through the registry hives of interest
ForEach ($reg_root in $reg_roots) {
    Get-ChildItem -Path $reg_root -Recurse | ForEach-Object {
        # Get all the sub-values
        $key = $_
        $key_name_printed = $false
        # Check each of the current key's values
        $key.GetValueNames() | ForEach-Object {
            $value_name = $_
            # Get the value held by the value name
            $value = $key.GetValue($value_name)
            # Perform case-insenstive comparison of the registry value against each target name
            ForEach ($target_name in $target_names) {
                if ($value -match $target_name) {
                    if ($key_name_printed -eq $false) {
                        Write-Output "+ $($key.Name)"
                        $key_name_printed = $true
                    }
                    Write-Output "|-------- $($value_name) _____ $($value)"
                }
            }
        }
        if ($key_name_printed) {
            Write-Output ""
        }
    }
}
