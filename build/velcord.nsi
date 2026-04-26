; Velcord Windows Installer Script (NSIS 3.x)
; This script creates a professional Windows installer for Velcord

!include "MUI2.nsh"
!include "x64.nsh"

; Product information
!define PRODUCT_NAME "Velcord"
!define PRODUCT_VERSION "1.0.0"
!define PRODUCT_PUBLISHER "Velcord"
!define PRODUCT_WEB_SITE "https://github.com/yourusername/velcord"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\velcord.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKCU"
!define MUI_ABORTWARNING
!define MUI_ICON "logo.png"
!define MUI_UNICON "logo.png"

SetCompressor /SOLID lzma
XPStyle on

; MUI Settings
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

; Installer attributes
Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "dist\VelcordSetup.exe"
InstallDir "$LOCALAPPDATA\Programs\Velcord"
ShowInstDetails show
ShowUnInstDetails show

; Install section
Section "Install"
  SetOutPath "$INSTDIR"
  
  ; Extract ZIP
  ${If} ${FileExists} "$EXEDIR\velcord-win-x64.zip"
    DetailPrint "Extracting application..."
    nsExec::ExecToLog 'powershell -NoProfile -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory(\"$EXEDIR\velcord-win-x64.zip\", \"$INSTDIR\", \$true)"'
  ${Else}
    MessageBox MB_ICONSTOP "Error: velcord-win-x64.zip not found in installer directory."
    Abort
  ${EndIf}
  
  ; Create Start Menu shortcut
  CreateDirectory "$SMPROGRAMS\Velcord"
  CreateShortcut "$SMPROGRAMS\Velcord\Velcord.lnk" "$INSTDIR\velcord.exe" "" "$INSTDIR\velcord.exe" 0
  CreateShortcut "$SMPROGRAMS\Velcord\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  
  ; Create Desktop shortcut
  CreateShortcut "$DESKTOP\Velcord.lnk" "$INSTDIR\velcord.exe" "" "$INSTDIR\velcord.exe" 0
  
  ; Create uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
  ; Registry entries
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "${PRODUCT_NAME}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  
  DetailPrint "Installation complete!"
SectionEnd

; Uninstaller section
Section "Uninstall"
  DetailPrint "Removing Velcord..."
  
  ; Delete application files
  RMDir /r "$INSTDIR"
  
  ; Delete shortcuts
  Delete "$SMPROGRAMS\Velcord\Velcord.lnk"
  Delete "$SMPROGRAMS\Velcord\Uninstall.lnk"
  RMDir "$SMPROGRAMS\Velcord"
  Delete "$DESKTOP\Velcord.lnk"
  
  ; Remove registry entries
  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  
  DetailPrint "Uninstall complete!"
SectionEnd

Function .onInstSuccess
  MessageBox MB_ICONINFORMATION|MB_TOPMOST "Velcord has been successfully installed!$\r$\nYou can now launch it from your Start Menu or Desktop."
FunctionEnd

Function un.onUninstSuccess
  MessageBox MB_ICONINFORMATION|MB_TOPMOST "Velcord has been successfully uninstalled."
FunctionEnd
