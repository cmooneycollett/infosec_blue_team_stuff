param (
    [Parameter(Mandatory=$true)]
    [string] $in_file
)
# Initialise count
$count = 0
$display_filter = "("
# Read each IP address listed in given file
Get-Content -Path $in_file | ForEach-Object {
    # Remove any leading or trailing whitespace
    $ip_addr = $_.Trim()
    if ($count -eq 0) {
        $display_filter += [String]::Format("frame matches == ""{0}""", $ip_addr)
    } else {
        $display_filter += [String]::Format(" || frame matches == ""{0}""", $ip_addr)
    }
    $count += 1
}
$display_filter += ")"
Write-Output $display_filter