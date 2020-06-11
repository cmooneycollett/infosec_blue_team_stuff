# Q1 - Find path for the KeyX keylogger process running on the computer
Write-Host -ForegroundColor Yellow "[?] Q1 - Find path for KeyX keylogger running on computer"

Get-Process | ? {$_.Name -match "KeyX"} | Select-Object -Property Name,Id,Path | Format-Table

# Q2, Q3 - look for *.log files modified a day either side of the known "teeamware.log" file
Write-Host -ForegroundColor Yellow "[?] Q2 - Finding *.log files modified within 2 minutes of teeamware.log"

$log_file_mod_date = (Get-Item -Path "C:\Users\Administrator\AppData\Roaming\teeamware.log").LastWriteTime
$start_date = $log_file_mod_date.AddMinutes(-2)
$end_date = $log_file_mod_date.AddMinutes(2)
Get-ChildItem -Path "C:\" -Recurse -Force -Include "*.log" -ErrorAction SilentlyContinue | Where-Object {
    $_.LastWriteTime -ge $start_date -and $_.LastWriteTime -le $end_date
}
