##### Function definitions

function Get-FileSignature {
    param (
        [string] $file_path,
        [string] $stream_name = ':$DATA'
    )
    $bytes = Get-Content -Path $file_path -Stream $stream_name -Encoding Byte -TotalCount 4
    $hex_header = ($bytes | ForEach-Object {$_.ToString("X2")}) -join ""
    return $hex_header
}

function Get-NTFSFileStreams {
    param (
        [string] $file_path
    )
    $streams = Get-Item -Path $file_path -Stream * | Select-Object -ExpandProperty Stream
    return $streams
}

function Get-NumNTFSFileStreams {
    param (
        [string] $file_path
    )
    $streams = Get-Item -Path $file_path -Stream * | Select-Object -ExpandProperty Stream
    return $streams | Measure-Object | Select-Object -ExpandProperty Count
}

##### Exercise script

# Get all files within the target directory, recursively
$all_files = Get-ChildItem -Path "C:\Users\DCI Student\Documents\IdentifyDataExfil_ADS" -Recurse

# Q1 - count number of RAR and ZIP files
$count = $all_files | Where-Object {$_.Extension -in (".rar",".zip")} | Measure-Object | Select-Object -ExpandProperty Count
Write-Host "[?] Q1 - $($count)"

# Q2 - count number of files with an ADS
$num_ads_files = 0
$ads_files = @()
ForEach ($file in $all_files) {
    $num_streams = Get-NumNTFSFileStreams -file_path $file.FullName
    if ($num_streams -gt 1) {
        $ads_files += $file
        $num_ads_files += 1
    }
}
Write-Host "[?] Q2 - $($num_ads_files)"

# Q3 - sort the ADS files by file name (needed in alphabetical order after this point)
[void] ($ads_files | Sort-Object -Property Name)
Write-Host "[?] Q3 - $(($ads_files | ForEach-Object {$_.Name}) -join ", ")"

# Q4 - get SHA1 filehash for all files containing an ADS. Hash is from the primary $DATA stream
$Q4_hashes = @()
ForEach ($file in $ads_files) {
    $sha1_hash = Get-FileHash -Path $file.FullName -Algorithm SHA1 | Select-Object -ExpandProperty Hash
    $Q4_hashes += $sha1_hash.Substring($sha1_hash.length - 4, 4)
}
Write-Host "[?] Q4 - $($Q4_hashes -join ", ")"

# Q5, Q7, Q9 - ASSUME only 1 additional data stream
$archive_file_sigs = @{
    "rar" = "52617221"
    "zip" = "504B0304"
}
# Mappings for Ex Q to applicable ADS
$ads_q = @{
    "Q5" = ("ads1", 0)
    "Q7" = ("ads2", 1)
    "Q9" = ("ads3", 2)
}
# Extract ADS from the applicable three files and inspect the 4-byte file header signature
ForEach ($question in $ads_q.Keys) {
    # Extract the contents of the ADS into a separate file
    $ads_index = $ads_q[$question][1]
    $stream_name = Get-Item -Path $ads_files[$ads_index].FullName -Stream * | Where-Object {$_.Stream -notmatch ":\`$DATA"} | Select-Object -ExpandProperty Stream
    $out_file = ".\$($ads_q[$question][0])_file.bin"
    Get-Content -Path $ads_files[$ads_index].FullName -Stream $stream_name -Encoding Byte | Set-Content -Path $out_file -Encoding Byte
    # Compare file sig
    $ads_file_sig = Get-FileSignature -file_path $out_file
    $sig_match = $false
    ForEach ($file_type in $archive_file_sigs.Keys) {
        if ($ads_file_sig -match $archive_file_sigs[$file_type]) {
            Write-Host "[?] $($question) - $($file_type) - 0x$($ads_file_sig)"
            $sig_match = $true
            break
        }
    }
    # If we don't have a signature match, print out the signature and the file contents
    if ($sig_match -eq $false) {
        Write-Host "[?] $($question) - NOT MATCH - header 0x$($ads_file_sig)"
        $contents = Get-Content -Path $out_file
        Write-Host "    -> $($contents)"
    }
}

# Generate signatures from all non-txt files, covering all data streams
$non_txt_sigs = New-Object System.Collections.Generic.HashSet[String]
ForEach ($file in ($all_files | Where-Object {$_.Extension -notin (".txt")})) {
    $streams = Get-NTFSFileStreams -file_path $file.FullName
    ForEach ($stream in $streams) {
        $signature = Get-FileSignature -file_path $file.FullName -stream_name $stream
        [void] $non_txt_sigs.Add($signature)
    }
}

# Q11 - check how many txt files have a signature that matches a non-txt file
$num_txt_mismatch_sig = 0
ForEach ($file in ($all_files | Where-Object {$_.Extension -in (".txt")})) {
    $txt_file_sig = Get-FileSignature -file_path $file.FullName
    if ($non_txt_sigs.Contains($txt_file_sig)) {
        $num_txt_mismatch_sig += 1
    }
}
Write-Host "[?] Q11 - $($num_txt_mismatch_sig)"
