# User to provide path to baseline and live hash lists
param (
        [Parameter(Mandatory=$true)]
        [string] $baseline,

        [Parameter(Mandatory=$true)]
        [string] $live
)
# Open CSV files
$baseline_import = Import-Csv -Path $baseline | sort
$live_import = Import-Csv -Path $live | sort
# Add baseline entries to dict - Key: SHA1, Entry: FileNames
$baseline_entries = @{}
$i = 0
ForEach ($entry in $baseline_import) {
    if (!$baseline_entries.ContainsKey($entry.SHA1)) {
        $baseline_entries.Add($entry.SHA1, $entry.FileNames)
    }
    Write-Progress -Activity "Adding baseline entries" -PercentComplete (($i / $baseline_import.Count) * 100)
    $i += 1
}
# For each entry in live hashes, check if the hash is in the baseline
$i = 0
ForEach ($entry in $live_import) {
    if (!$baseline_entries.ContainsKey($entry.SHA1)) {
        Write-Output "SHA1 hash not found in baseline: [$($entry.SHA1)] $($entry.FileNames)"
    }
    Write-Progress -Activity "Checking live hashes against baseline" -PercentComplete (($i / $live_import.Count) * 100)
    $i += 1
}
