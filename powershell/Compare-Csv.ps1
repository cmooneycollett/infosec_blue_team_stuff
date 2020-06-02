param (
        [Parameter(Mandatory=$true)]
        [string] $baseline,
        [Parameter(Mandatory=$true)]
        [string] $live,
        [Parameter(Mandatory=$true)]
        [string] $column
)
# Build the baseline hashset
$baseline_set = New-Object System.Collections.Generic.HashSet[string]
$baseline_import = Import-Csv -Path $baseline | Sort-Object -Property Name
$live_import = Import-Csv -Path $live | Sort-Object -Property Name
$i = 0
ForEach ($entry in $baseline_import) {
    [void]$baseline_set.Add($entry.$column)
    Write-Progress -Activity "Adding baseline entries" -PercentComplete (($i / $baseline_import.Count) * 100)
    $i += 1
}
# Check the live against the baseline
ForEach ($entry in $live_import) {
    if ($baseline_set.Contains($entry.$column) -eq $false) {
        Write-Output "Not in baseline: $($entry.$column)"
    }
}