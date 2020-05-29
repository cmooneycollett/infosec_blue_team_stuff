param (
    [Parameter(Mandatory=$true)]
    [string] $in_file
)
# Initialise count
$count = 0
$display_filter = "("
# Read each domain listed in given file and add to display filter
Get-Content -Path $in_file | ForEach-Object {
    # Remove any leading or trailing whitespace
    $domain = $_.Trim()
    # Remove leading "period" character for domain names with redacted components
    if ($domain.StartsWith(".")) {
        $domain = $domain.Substring(1, $domain.Length - 1)
    }
    if ($count -eq 0) {
        $display_filter += [String]::Format("frame contains ""{0}""", $domain)
    } else {
        $display_filter += [String]::Format(" || frame contains ""{0}""", $domain)
    }
    $count += 1
}
$display_filter += ")"
Write-Output $display_filter