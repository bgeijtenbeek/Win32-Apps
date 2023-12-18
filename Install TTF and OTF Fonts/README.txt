###################
Usage info
###################

Package installs .ttf & .otf font files to your computer for computer-wide use.

- Download the files (especially the _source folder)
- Place your .ttf & .otf files in the _source\Fonts folder (you can use subfolders if you would like).
- Package the _source folder in to an intunewin (Win32) file.

The script will write a custom regkey for detection of the app. Think about where you want that location to be and use the following parameters for the install/uninstall command:
-CustomRegKey (not mandatory): when used you can enter a custom regkey name (HKLM:\SOFTWARE\CustomName). When not used, the default "CustomIntuneDetection" will be used.
-CustomRegItem (mandatory): the item that you want to create for detection. For example: FontPack01. This will get the value "Installed" and can then be used for detection.

You can also use the -Log parameter to write a transcript of the script to C:\Temp\InstallLogs\.

- Upload to Intune and use the following commands/settings to install.


#########################
Intune commands/settings
#########################

INSTALLATION

Install commands examples:
%windir%\SysNative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -command ".\install.ps1" -CustomRegItem 'FontPack01'
%windir%\SysNative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -command ".\install.ps1" -CustomRegItem 'FontPack01' -CustomRegKey "CustomFonts" -Log

Uninstall commands examples:
%windir%\SysNative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -command ".\uninstall.ps1" -CustomRegItem 'FontPack01'
%windir%\SysNative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -command ".\uninstall.ps1" -CustomRegItem 'FontPack01' -CustomRegKey "CustomFonts" -Log

DETECTION

Look for a regkey depending on what you chose in the above settings. Compare the string to "Installed" if you want. 
App is NOT associated with 32-bits app on a 64-bits machine.
