# Tries several NSIS release URLs and extracts makensis.exe into node_modules/app-builder-bin/win/x64
$urls = @(
    'https://downloads.sourceforge.net/project/nsis/NSIS%203/3.08.1/nsis-3.08.1.zip',
    'https://github.com/kichik/nsis/releases/download/3.08.1/nsis-3.08.1.zip',
    'https://github.com/kichik/nsis/releases/download/3.08.0/nsis-3.08.0.zip',
    'https://github.com/kichik/nsis/releases/download/3.07.1/nsis-3.07.1.zip'
)
$dest = "node_modules\\app-builder-bin\\win\\x64"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
$success = $false
foreach ($u in $urls) {
    Write-Host "Trying $u"
    $tmp = Join-Path $env:TEMP 'nsis.zip'
    try {
        Invoke-WebRequest -Uri $u -OutFile $tmp -UseBasicParsing -ErrorAction Stop
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $extract = Join-Path $env:TEMP ('nsis_extract_' + (Get-Random))
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tmp, $extract)
        $found = Get-ChildItem -Path $extract -Filter makensis.exe -Recurse -ErrorAction SilentlyContinue
        if ($found) {
            Copy-Item $found[0].FullName -Destination (Join-Path $dest 'makensis.exe') -Force
            Write-Host 'Copied makensis.exe to ' $dest
            $success = $true
            break
        }
    } catch {
        Write-Host 'Download/extract failed:' $_.Exception.Message
    }
}
if (-not $success) {
    Write-Host 'No makensis.exe found from tried URLs'
    exit 2
}
Write-Host 'makensis acquired successfully'
exit 0
