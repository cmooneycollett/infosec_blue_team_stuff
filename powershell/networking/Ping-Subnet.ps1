0..255 | % {
    Write-Output "192.168.13.$_"; ping -n 1 -w 10 192.168.13.$_ | Select-String ttl
}