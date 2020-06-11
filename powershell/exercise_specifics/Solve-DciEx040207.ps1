# Q1 - Search through entire C: drive for all files called "KeyX.exe"
Get-ChildItem -Path "C:\" -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_ -isnot [System.IO.DirectoryInfo]) {
        if ($_.Name -eq "KeyX.exe") {
            Write-Host $_.FullName
        }
    }
}
# Q2, Q3 - look for *.log files modified a day either side of the known "teeamware.log" file
$log_file_mod_date = (Get-Item -Path "C:\Users\DCI Student\AppData\Roaming\teeamware.log").LastWriteTime
$start_date = $log_file_mod_date.AddDays(-1)
$end_date = $log_file_mod_date.AddDays(1)
Get-ChildItem -Path "C:\" -Recurse -Force -Include "*.log" -ErrorAction SilentlyContinue | Where-Object {
    $_.LastWriteTime -ge $start_date -and $_.LastWriteTime -le $end_date
}
