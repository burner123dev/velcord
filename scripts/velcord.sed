[Version]
Class=IEXPRESS
SEDVersion=3

[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=0
UseLongFileNames=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=I
InstallMode=DefaultInstall
CompressionType=MSZIP
CreatePrompt=Do you want to install Velcord?
DisplayLicense=
FinishMessage=Velcord has been installed. You can now launch it from your Start Menu or Desktop.
TargetName=dist\VelcordSetup.exe
FriendlyName=Velcord Installer
AppLaunched=install.bat
PostInstallCmd=
AdminQuietInstCmd=
UserQuietInstCmd=
SourceFiles=SourceFileList

[SourceFiles]
SourceFileList=

[SourceFileList]
%CD%\dist\velcord-win-x64.zip
%CD%\dist\VelcordInstaller.bat

[Strings]
