$ErrorActionPreference = 'Stop'
$source = Join-Path (Get-Location) 'dist\win-unpacked'
$dest = Join-Path $env:LOCALAPPDATA 'Programs\Velcord'
Write-Host "Installing Velcord from $source to $dest"
if (!(Test-Path $source)) { Write-Error "Source path not found: $source"; exit 1 }
if (Test-Path $dest) { Write-Host "Removing existing install at $dest"; Remove-Item -Recurse -Force $dest }
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Write-Host 'Copying files...'
Copy-Item -Path (Join-Path $source '*') -Destination $dest -Recurse -Force

# Create Start Menu shortcut
$ws = New-Object -ComObject WScript.Shell
$startMenuFolder = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$shortcutDir = Join-Path $startMenuFolder 'Velcord'
if (!(Test-Path $shortcutDir)) { New-Item -ItemType Directory -Force -Path $shortcutDir | Out-Null }
$linkPath = Join-Path $shortcutDir 'Velcord.lnk'
$target = Join-Path $dest 'velcord.exe'
$sh = $ws.CreateShortcut($linkPath)
$sh.TargetPath = $target
$sh.WorkingDirectory = $dest
$sh.IconLocation = $target
$sh.Save()
Write-Host "Start Menu shortcut created: $linkPath"

# Create Desktop shortcut
$desktop = [Environment]::GetFolderPath('Desktop')
$deskLink = Join-Path $desktop 'Velcord.lnk'
$sh2 = $ws.CreateShortcut($deskLink)
$sh2.TargetPath = $target
$sh2.WorkingDirectory = $dest
$sh2.IconLocation = $target
$sh2.Save()
Write-Host "Desktop shortcut created: $deskLink"

# Create uninstall script
$uninstall = Join-Path $dest 'uninstall.ps1'
@"
Write-Host 'Uninstalling Velcord...'
try {
    Remove-Item -Recurse -Force '$dest' -ErrorAction SilentlyContinue
    Remove-Item -Force '$linkPath' -ErrorAction SilentlyContinue
    Remove-Item -Force '$deskLink' -ErrorAction SilentlyContinue
    Remove-Item -Force '$uninstall' -ErrorAction SilentlyContinue
    Write-Host 'Uninstalled.'
} catch {
    Write-Error "Failed to uninstall: $_"
}
"@ | Out-File -FilePath $uninstall -Encoding utf8 -Force

Write-Host "Installed Velcord to $dest"
Write-Host "Run $target to start. Uninstall script: $uninstall"
