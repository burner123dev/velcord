$zip = Join-Path $env:TEMP 'nsis_portable_retry.zip'
$url = 'https://prdownloads.sourceforge.net/nsis/nsis-3.08.1.zip'
if (Test-Path $zip) { Remove-Item $zip -Force }
Write-Host "Downloading NSIS from $url to $zip"
Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing -ErrorAction Stop
$len = (Get-Item $zip).Length
Write-Host "Downloaded bytes: $len"
$tmpdir = Join-Path $env:TEMP 'nsis_extract_retry'
Remove-Item -Recurse -Force $tmpdir -ErrorAction SilentlyContinue
Expand-Archive -Path $zip -DestinationPath $tmpdir -Force
Write-Host "Extracted to $tmpdir"
$found = Get-ChildItem -Path $tmpdir -Filter makensis.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -ne $found) {
    Write-Host "Found makensis at $($found.FullName)"
    $dest = Join-Path (Join-Path (Get-Location) 'node_modules\app-builder-bin\win\x64') 'makensis.exe'
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    Copy-Item -Path $found.FullName -Destination $dest -Force
    Write-Host "Copied makensis to $dest"
} else {
    Write-Host "makensis not found in archive"
}
