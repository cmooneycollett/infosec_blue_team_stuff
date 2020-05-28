# Initialise array with names of target bad files
$bad_files = (
    "extrac32.exe",
    "jackinthebox.exe",
    "excel2017.exe",
    "sxstrace.exe"
)
# Check entire "C:" drive for instances of files with a target name
Get-ChildItem -Path "C:\" -Recurse | ForEach-Object {
    $bad_files.Contains($_.Name)
}