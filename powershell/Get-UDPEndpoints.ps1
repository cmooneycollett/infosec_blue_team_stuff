# Get set of all processes
$Processes = @{}
Get-Process -IncludeUserName | % { $Processes.Add($_.Id, $_) }

# Get UDP endpoints
Get-NetUDPEndpoint |
    Where-Object {$_.LocalAddress -eq "0.0.0.0"} |
    Select-Object LocalAddress,
        LocalPort,
        @{Name="PID"; Expression={$_.OwningProcess}},
        @{Name="ProcessName"; Expression={$Processes[[int]$_.OwningProcess].ProcessName}},
        @{Name="UserName"; Expression={$Processes[[int]$_.OwningProcess].UserName}},
        @{Name="Path"; Expression={$Processes[[int]$_.OwningProcess].Path}} |
    Format-Table -AutoSize
