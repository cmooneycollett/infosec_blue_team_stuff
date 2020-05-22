param (
        [Parameter(Mandatory=$true)]
        [string] $baseline,
        [Parameter(Mandatory=$true)]
        [string] $target_dir,
        [Parameter(Mandatory=$true)]
        [string] $hash_alg # SHA1
)
# Import baseline csv
$baseline_table = @{}
Import-Csv $baseline -Delimiter "," | ForEach-Object {
    if ($hash_alg -eq "MD5") {
        $baseline_table[$_.MD5] = $_.FileNames
    } elseif ($hash_alg -eq "SHA1") {
        $baseline_table[$_.SHA1] = $_.FileNames
    } else {
        throw "Bad hash_alg: must be SHA1 or MD5"
    }
}
# Check the target dir
Get-ChildItem $target_dir | ForEach-Object {
    Get-FileHash $_.FullName -Algorithm $hash_alg |
    Where-Object {
        !$baseline_table.ContainsKey($_.hash)
    }
} | Format-Table -AutoSize
