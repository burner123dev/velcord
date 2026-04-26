@echo off
REM Velcord Installer
REM Extracts and installs Velcord to user's local programs directory

setlocal enabledelayedexpansion

set "INSTALL_DIR=%LOCALAPPDATA%\Programs\Velcord"
set "START_MENU_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Velcord"
set "DESKTOP_DIR=%USERPROFILE%\Desktop"
set "ZIP_FILE=%~dp0..\dist\velcord-win-x64.zip"

echo ==============================
echo Velcord Installer
echo ==============================
echo.
echo Installing to: %INSTALL_DIR%
echo.

REM Check if ZIP exists
if not exist "%ZIP_FILE%" (
    echo Error: %ZIP_FILE% not found.
    echo Please ensure the portable app ZIP is present.
    pause
    exit /b 1
)

REM Remove old installation
if exist "%INSTALL_DIR%" (
    echo Removing old installation...
    rmdir /s /q "%INSTALL_DIR%" >nul 2>&1
)

REM Create install directory
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%"
)

REM Extract ZIP using PowerShell
echo Extracting application...
powershell -NoProfile -Command ^
    "Add-Type -AssemblyName System.IO.Compression.FileSystem; ^
    [System.IO.Compression.ZipFile]::ExtractToDirectory('%ZIP_FILE%', '%INSTALL_DIR%', $true); ^
    Write-Host 'Extraction complete.'"

if errorlevel 1 (
    echo Failed to extract ZIP file.
    pause
    exit /b 1
)

REM Create shortcuts
echo Creating shortcuts...

REM Create Start Menu directory
if not exist "%START_MENU_DIR%" (
    mkdir "%START_MENU_DIR%"
)

REM Create Start Menu shortcut using PowerShell
powershell -NoProfile -Command ^
    "$shell = New-Object -ComObject WScript.Shell; ^
    $shortcut = $shell.CreateShortcut('%START_MENU_DIR%\Velcord.lnk'); ^
    $shortcut.TargetPath = '%INSTALL_DIR%\velcord.exe'; ^
    $shortcut.IconLocation = '%INSTALL_DIR%\velcord.exe'; ^
    $shortcut.Save(); ^
    Write-Host 'Start Menu shortcut created.'"

REM Create Desktop shortcut using PowerShell
powershell -NoProfile -Command ^
    "$shell = New-Object -ComObject WScript.Shell; ^
    $shortcut = $shell.CreateShortcut('%DESKTOP_DIR%\Velcord.lnk'); ^
    $shortcut.TargetPath = '%INSTALL_DIR%\velcord.exe'; ^
    $shortcut.IconLocation = '%INSTALL_DIR%\velcord.exe'; ^
    $shortcut.Save(); ^
    Write-Host 'Desktop shortcut created.'"

REM Create uninstaller batch file
echo Creating uninstaller...
(
    echo @echo off
    echo echo Uninstalling Velcord...
    echo rmdir /s /q "%INSTALL_DIR%" >nul 2^>^&1
    echo rmdir /s /q "%START_MENU_DIR%" >nul 2^>^&1
    echo del /f /q "%DESKTOP_DIR%\Velcord.lnk" >nul 2^>^&1
    echo echo Velcord has been uninstalled.
    echo pause
) > "%INSTALL_DIR%\uninstall.bat"

REM Success message
echo.
echo ==============================
echo Installation Complete!
echo ==============================
echo.
echo Velcord installed to: %INSTALL_DIR%
echo Start Menu: %START_MENU_DIR%\Velcord.lnk
echo Desktop: %DESKTOP_DIR%\Velcord.lnk
echo.
echo You can now launch Velcord from the Start Menu or Desktop.
echo To uninstall, run: %INSTALL_DIR%\uninstall.bat
echo.
pause
exit /b 0
