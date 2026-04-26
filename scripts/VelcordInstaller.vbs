Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

Const HKEY_CURRENT_USER = &H80000001
strComputer = "."

' Get paths
strLocalAppData = objShell.ExpandEnvironmentStrings("%LOCALAPPDATA%")
strAppData = objShell.ExpandEnvironmentStrings("%APPDATA%")
strUserProfile = objShell.ExpandEnvironmentStrings("%USERPROFILE%")
strScriptPath = objFSO.GetParentFolderName(WScript.ScriptFullName)
strInstallDir = objFSO.BuildPath(strLocalAppData, "Programs\Velcord")
strStartMenuDir = objFSO.BuildPath(strAppData, "Microsoft\Windows\Start Menu\Programs\Velcord")
strDesktopDir = objFSO.BuildPath(strUserProfile, "Desktop")
strZipFile = objFSO.BuildPath(strScriptPath, "..\dist\velcord-win-x64.zip")

objShell.Popup "==============================" & vbCrLf & "Velcord Installer" & vbCrLf & "==============================", 0, "Velcord Installer", vbInformation

' Check if ZIP exists
If Not objFSO.FileExists(strZipFile) Then
    objShell.Popup "Error: " & strZipFile & " not found." & vbCrLf & "Please ensure the portable app ZIP is present.", 0, "Velcord Installer", vbCritical
    WScript.Quit 1
End If

' Remove old installation
If objFSO.FolderExists(strInstallDir) Then
    On Error Resume Next
    objFSO.DeleteFolder strInstallDir, True
    On Error Goto 0
End If

' Create install directory
If Not objFSO.FolderExists(strInstallDir) Then
    objFSO.CreateFolder strInstallDir
End If

' Extract ZIP using PowerShell
objShell.Popup "Extracting application...", 0, "Velcord Installer", vbInformation
Dim strCmd
strCmd = "powershell -NoProfile -Command ""Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('" & strZipFile & "', '" & strInstallDir & "', $true)"""
objShell.Run strCmd, 0, True

' Create Start Menu directory
If Not objFSO.FolderExists(strStartMenuDir) Then
    objFSO.CreateFolder strStartMenuDir
End If

' Create Start Menu shortcut
Dim objShortcut
Set objShortcut = objShell.CreateShortcut(objFSO.BuildPath(strStartMenuDir, "Velcord.lnk"))
objShortcut.TargetPath = objFSO.BuildPath(strInstallDir, "velcord.exe")
objShortcut.IconLocation = objFSO.BuildPath(strInstallDir, "velcord.exe")
objShortcut.Save

' Create Desktop shortcut
Set objShortcut = objShell.CreateShortcut(objFSO.BuildPath(strDesktopDir, "Velcord.lnk"))
objShortcut.TargetPath = objFSO.BuildPath(strInstallDir, "velcord.exe")
objShortcut.IconLocation = objFSO.BuildPath(strInstallDir, "velcord.exe")
objShortcut.Save

' Create uninstaller batch file
Dim strUninstallBat
strUninstallBat = "@echo off" & vbCrLf & _
    "echo Uninstalling Velcord..." & vbCrLf & _
    "rmdir /s /q """ & strInstallDir & """ >nul 2>&1" & vbCrLf & _
    "rmdir /s /q """ & strStartMenuDir & """ >nul 2>&1" & vbCrLf & _
    "del /f /q """ & objFSO.BuildPath(strDesktopDir, "Velcord.lnk") & """ >nul 2>&1" & vbCrLf & _
    "echo Velcord has been uninstalled." & vbCrLf & _
    "pause"

Dim objFile
Set objFile = objFSO.CreateTextFile(objFSO.BuildPath(strInstallDir, "uninstall.bat"), True)
objFile.Write strUninstallBat
objFile.Close

' Success message
objShell.Popup "Installation Complete!" & vbCrLf & vbCrLf & _
    "Velcord installed to: " & strInstallDir & vbCrLf & _
    "Start Menu: " & objFSO.BuildPath(strStartMenuDir, "Velcord.lnk") & vbCrLf & _
    "Desktop: " & objFSO.BuildPath(strDesktopDir, "Velcord.lnk") & vbCrLf & vbCrLf & _
    "You can now launch Velcord from the Start Menu or Desktop.", 0, "Velcord Installer", vbInformation

WScript.Quit 0
