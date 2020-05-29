param (
    [Parameter(Mandatory=$true)]
    [string] $in_file,
    [Parameter(Mandatory=$true)]
    [string] $field
)
# Import the infile as CSV
$import_csv = Import-Csv -Path $in_file
# Initialise hashset to record the unique instances of field observed
$uniq_results = New-Object System.Collections.Generic.HashSet[String]
ForEach ($entry in $import_csv) {
    # Extract the desired field from the entry
    $extract_field = $entry.$field
    # Check that the extracted field is not empty
    if ($extract_field.Length -gt 0) {
        [void]$uniq_results.Add($extract_field)
    }
}
$uniq_results = $uniq_results | Sort-Object
Write-Output $uniq_results