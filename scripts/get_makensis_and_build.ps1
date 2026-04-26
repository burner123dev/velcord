# Downloads NSIS zip releases, extracts makensis.exe into node_modules/app-builder-bin/win/x64,
# then runs electron-builder to create an NSIS installer.

$ErrorActionPreference = 'Stop'

$urls = @(
    'https://github.com/kichik/nsis/releases/download/v3.08.1/nsis-3.08.1.zip',
    'https://github.com/kichik/nsis/releases/download/v3.08.0/nsis-3.08.0.zip',
    'https://github.com/kichik/nsis/releases/download/v3.07.1/nsis-3.07.1.zip',
    'https://downloads.sourceforge.net/project/nsis/NSIS%203/3.08.1/nsis-3.08.1.zip'
)

$projectRoot = (Resolve-Path ".").Path
$dest = Join-Path $projectRoot 'node_modules\app-builder-bin\win\x64'
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$success = $false
foreach ($u in $urls) {
    try {
        Write-Host "Attempting download: $u"
        $tmp = Join-Path $env:TEMP "nsis_dl_$([guid]::NewGuid()).zip"
        Invoke-WebRequest -Uri $u -OutFile $tmp -UseBasicParsing -ErrorAction Stop
        $extract = Join-Path $env:TEMP ("nsis_extract_$([guid]::NewGuid())")
        Write-Host "Extracting to: $extract"
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tmp, $extract)
        Write-Host "Searching for makensis.exe in extracted files..."
        $found = Get-ChildItem -Path $extract -Filter makensis.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $target = Join-Path $dest 'makensis.exe'
            Copy-Item -Path $found.FullName -Destination $target -Force
            Write-Host "Copied makensis.exe to: $target"
            $success = $true
            Remove-Item -Path $tmp -Force -ErrorAction SilentlyContinue
            break
        } else {
            Write-Host "makensis.exe not found in this archive. Cleaning up and trying next URL."
            Remove-Item -Path $tmp -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $extract -Recurse -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Host ("Download or extract failed for {0}: {1}" -f $u, $_.Exception.Message)
    }
}

if (-not $success) {
    Write-Host "Failed to obtain makensis.exe from known URLs. Exiting with code 2."
    exit 2
}

Write-Host "Verified makensis at:" (Get-Item (Join-Path $dest 'makensis.exe')).FullName

Write-Host "Running electron-builder NSIS..."
$cmd = 'pnpm exec electron-builder --win nsis "-c.extraMetadata.main=dist/js/main.js" --x64 --publish never'
Write-Host $cmd

# Use cmd/exe to run so PATH is resolved the same as interactive shell
$process = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', $cmd -NoNewWindow -Wait -PassThru
if ($process.ExitCode -ne 0) {
    Write-Host "electron-builder exited with code $($process.ExitCode)"
    exit $process.ExitCode
}

Write-Host "electron-builder completed successfully. Check dist for installer (.exe)."
exit 0
