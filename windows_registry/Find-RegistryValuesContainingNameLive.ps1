param (
    [Parameter(Mandatory=$true)]
    [string] $in_file
)
# Open the in-file and read into list
$target_names = Get-Content -Path $in_file | % {$_.ToLower()}
# Initialise registry roots
$reg_roots = (
    "HKCU:\",
    "HKLM:\",
    "HKU:\"
)
# Recurse through the registry hives of interest
ForEach ($reg_root in $reg_roots) {
    Get-ChildItem -Path $reg_root -Recurse | % {
        # Get all the sub-values
        $key = $_
        # Check each of the current key's values
        $key.GetValueNames() | % {
            $value_name = $_
            # Get the value held by the value name
            $value = $key.GetValue($value_name)
            # Perform case-insenstive comparison of the registry value against each target name
            ForEach ($target_name in $target_names) {
                if ($value -match $target_name) {
                    Write-Output "+ $($key.Name)"
                    Write-Output "|-------- $($value_name) _____ $($value)"
                    Write-Output ""
                }
            }
        }
    }
}
