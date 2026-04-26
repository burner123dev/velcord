# Advanced NSIS downloader with multiple fallback sources
$sources = @(
    'https://sourceforge.net/projects/nsis/files/NSIS%203/3.08.1/nsis-3.08.1-setup.exe',
    'https://master.dl.sourceforge.net/project/nsis/NSIS%203/3.08.1/nsis-3.08.1-setup.exe',
    'https://iweb.dl.sourceforge.net/project/nsis/NSIS%203/3.08.1/nsis-3.08.1-setup.exe'
)

$dest = "node_modules\app-builder-bin\win\x64\makensis.exe"
New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null

foreach ($src in $sources) {
    try {
        Write-Host "Trying: $src"
        $tmp = Join-Path $env:TEMP "nsis_setup_$([guid]::NewGuid()).exe"
        Invoke-WebRequest -Uri $src -OutFile $tmp -UseBasicParsing -TimeoutSec 30
        
        # Extract makensis.exe from installer
        Write-Host "Extracting makensis from setup..."
        $extract = Join-Path $env:TEMP "nsis_extract_$([guid]::NewGuid())"
        & "$tmp" /D=$extract | Out-Null
        Start-Sleep -Seconds 2
        
        $makensis = Get-ChildItem -Path $extract -Filter makensis.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($makensis) {
            Copy-Item $makensis.FullName -Destination $dest -Force
            Write-Host "Success! Extracted makensis to: $dest"
            
            # Verify
            if (Test-Path $dest) {
                $ver = & $dest --version 2>&1
                Write-Host "Makensis version: $ver"
                exit 0
            }
        }
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "Failed: $($_.Exception.Message)"
    }
}

Write-Host "All attempts exhausted."
exit 1
