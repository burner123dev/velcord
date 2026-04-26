$zip = Join-Path $env:TEMP 'nsis_portable.zip'
$url = 'https://prdownloads.sourceforge.net/nsis/nsis-3.08.1.zip'
Write-Host "Downloading $url to $zip"
Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing -ErrorAction Stop
$destdir = Join-Path $env:TEMP 'nsis_portable'
Remove-Item -Recurse -Force $destdir -ErrorAction SilentlyContinue
Expand-Archive -Path $zip -DestinationPath $destdir -Force
Write-Host "Searching for makensis.exe in $destdir"
$found = Get-ChildItem -Path $destdir -Filter makensis.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -ne $found) {
    Write-Host "Found: $($found.FullName)"
    $target = Join-Path (Join-Path (Get-Location) 'node_modules\app-builder-bin\win\x64') 'makensis.exe'
    New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
    Copy-Item -Path $found.FullName -Destination $target -Force
    Write-Host "Copied to $target"
} else {
    Write-Host "makensis not found in archive"
}
