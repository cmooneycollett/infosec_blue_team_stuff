# Q1
$Q1_files = Get-ChildItem -Path "C:\Users\DCI Student\Documents\IdentifyDataExfil_ADS" -Recurse -Include "*.zip","*.rar"
$count = $Q1_files | Measure-Object | Select-Object -ExpandProperty Count
Write-Host "[?] Q1 - $($count)"

# Q2
$Q2_files = Get-ChildItem -Path "C:\Users\DCI Student\Documents\IdentifyDataExfil_ADS" -Recurse
$num_ads_files = 0
$ads_files = @()
ForEach ($file in $Q2_files) {
    $num_streams = Get-Item -Path $file.FullName -Stream * | Measure-Object | Select-Object -ExpandProperty Count
    if ($num_streams -gt 1) {
        $ads_files += $file
        $num_ads_files += 1
    }
}
Write-Host "[?] Q2 - $($num_ads_files)"

# Q3
[void] ($ads_files | Sort-Object -Property Name)
Write-Host "[?] Q3 - $(($ads_files | % {$_.Name}) -join ", ")"

# Q4
$Q4_hashes = @()
ForEach ($file in $ads_files) {
    $sha1_hash = Get-FileHash -Path $file.FullName -Algorithm SHA1 | Select-Object -ExpandProperty Hash
    $Q4_hashes += $sha1_hash.Substring($sha1_hash.length - 4, 4)
}
Write-Host "[?] Q4 - $($Q4_hashes -join ", ")"

# Q5
$file_sigs = @{
    "rar" = "52617221"
    "zip" = "504B0304"
}

$ads1_stream_name = Get-Item -Path $ads_files[0].FullName -Stream * | Where-Object {$_.Stream -notmatch "DATA"} | Select-Object -ExpandProperty Stream
Get-Content -Path $ads_files[0].FullName -Stream $ads1_stream_name -Encoding Byte | Set-Content -Path ".\ads1_file.rar" -Encoding Byte
$Q5_hex_header = ""
Get-Content -Path ".\ads1_file.rar" -Encoding Byte -TotalCount 4 | % {
    if (("{0:X}" -f $_).length -eq 1) {
        $Q5_hex_header += "0{0:X}" -f $_
    } else {
        $Q5_hex_header += "{0:X}" -f $_
    }
}
$Q5_match = $false
ForEach ($file_type in $file_sigs.Keys) {
    if ($Q5_hex_header -match $file_sigs[$file_type]) {
        Write-Host "[?] Q5 - $($file_type) - 0x$($Q5_hex_header)"
        $Q5_match = $true
    }
    if ($Q5_match -eq $true) {
        break;
    }
}
if ($Q5_match -eq $false) {
    Write-Host "[?] Q5 - NOT MATCH - header 0x$($Q5_hex_header))"
}

# Q7
$ads2_stream_name = Get-Item -Path $ads_files[1].FullName -Stream * | Where-Object {$_.Stream -notmatch "DATA"} | Select-Object -ExpandProperty Stream
Get-Content -Path $ads_files[1].FullName -Stream $ads2_stream_name -Encoding Byte | Set-Content -Path ".\ads2_file.zip" -Encoding Byte
$Q7_hex_header = ""
Get-Content -Path ".\ads2_file.zip" -Encoding Byte -TotalCount 4 | % {
    if (("{0:X}" -f $_).length -eq 1) {
        $Q7_hex_header += "0{0:X}" -f $_
    } else {
        $Q7_hex_header += "{0:X}" -f $_
    }
}
$Q7_match = $false
ForEach ($file_type in $file_sigs.Keys) {
    if ($Q7_hex_header -match $file_sigs[$file_type]) {
        Write-Host "[?] Q7 - $($file_type) - 0x$($Q7_hex_header)"
        $Q7_match = $true
    }
    if ($Q7_match -eq $true) {
        break;
    }
}
if ($Q7_match -eq $false) {
    Write-Host "[?] Q7 - NOT MATCH - header 0x$($Q7_hex_header))"
}

# Q9
$ads3_stream_name = Get-Item -Path $ads_files[2].FullName -Stream * | Where-Object {$_.Stream -notmatch "DATA"} | Select-Object -ExpandProperty Stream
Get-Content -Path $ads_files[2].FullName -Stream $ads3_stream_name -Encoding Byte | Set-Content -Path ".\ads3_file.txt" -Encoding Byte
$Q9_hex_header = ""
Get-Content -Path ".\ads3_file.txt" -Encoding Byte -TotalCount 4 | % {
    if (("{0:X}" -f $_).length -eq 1) {
        $Q9_hex_header += "0{0:X}" -f $_
    } else {
        $Q9_hex_header += "{0:X}" -f $_
    }
}
$Q9_match = $false
ForEach ($file_type in $file_sigs.Keys) {
    if ($Q9_hex_header -match $file_sigs[$file_type]) {
        Write-Host "[?] Q9 - $($file_type) - 0x$($Q9_hex_header)"
        $Q9_match = $true
    }
    if ($Q9_match -eq $true) {
        break;
    }
}
if ($Q9_match -eq $false) {
    Write-Host "[?] Q9 - NOT MATCH - header 0x$($Q9_hex_header)"
    Get-Content -Path $ads_files[2].FullName -Stream $ads3_stream_name
}

# Generate signatures
$sigs = @()
$no_txt_files = $Q11_files = Get-ChildItem -Path "C:\Users\DCI Student\Documents\IdentifyDataExfil_ADS" -Recurse -Exclude "*.txt"
ForEach ($file in $no_txt_files) {
    $hex_header = ""
    Get-Content -Path $file.FullName -Encoding Byte -TotalCount 4 -ErrorAction SilentlyContinue | % {
        if (("{0:X}" -f $_).length -eq 1) {
            $hex_header += "0{0:X}" -f $_
        } else {
            $hex_header += "{0:X}" -f $_
        }
    }
    $sigs += $hex_header
}

# Q11
$Q11_files = Get-ChildItem -Path "C:\Users\DCI Student\Documents\IdentifyDataExfil_ADS" -Recurse -Include "*.txt"
$num_txt_mismatch_sig = 0
ForEach ($file in $Q11_files) {
    $hex_header = ""
    Get-Content -Path $file.FullName -Encoding Byte -TotalCount 4 | % {
        if (("{0:X}" -f $_).length -eq 1) {
            $hex_header += "0{0:X}" -f $_
        } else {
            $hex_header += "{0:X}" -f $_
        }
    }
    if ($sigs.Contains($hex_header) -eq $true) {
        $num_txt_mismatch_sig += 1
    }
}
Write-Host "[?] Q11 - $($num_txt_mismatch_sig)"
