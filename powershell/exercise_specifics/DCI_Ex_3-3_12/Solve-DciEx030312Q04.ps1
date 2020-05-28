# Initialise array with names of target bad files
$bad_files = @{
    "extrac32.exe" = $true
    "jackinthebox.exe" = $true
    "excel2017.exe" = $true
    "sxstrace.exe" = $true
}
# Check entire "C:" drive for instances of files with a target name
Get-ChildItem -Path "C:\" -Recurse | ForEach-Object {
    if ($bad_files.ContainsKey($_.Name)) {
        Write-Output "[+] Live system contains bad file: $($_.FullName)"
    }
}