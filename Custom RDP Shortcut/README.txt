###################
Usage info
###################

Package installs .rdp shortcuts in the StartMenu.

- Remove the demo content from the "_source\Files" folder.
- Place your .rdp file(s) in the "_source\Files" folder. Can be one, can be multiple.
- If you want to use custom icons for you StartMenu shortcuts, place your .ico file(s) in the "_source\Files" folder. Can be one, can be multiple.
- Make sure the .rdp and .ico file that belong together have the same name, otherwise the script will fail to combine them in the StartMenu shortcuts.
- Make sure these names are the same as the eventual shortcut name you want to add to the StartMenu.
- Run the Win32 Content Prep Tool to package the _source folder in to a .intunewin file.
- Upload the .intunewin to Intune.

Then think about:
- installation context -> you want to make it available for all users on the device or only for specific users? Do you want to install the shortcuts in User context or Device context?
- whether you want to add the StartMenu shortcuts independantly or that you would like to put them in a (new or already existing) folder?

When you have the answers, make sure to use the proper parameters to install.

USER/DEVICE CONTEXT
use the -User or -Device install parameter.

USE STARTMENU SUBFOLDER OR NOT
when you want the shortcuts to be placed in a subfolder, use the -StartMenuFolder parameter followed by the folder name. 
This can be a new or already existing subfolder, the script will take care of it. Also, when using the uninstall script the subfolder will be automatically deleted as well, but only when it's empty!
If you don't want the shortcuts in a subfolder, just don't add the -StartMenuFolder parameter to the installation. 

LOG
when you would like to write a log of the process add the -Log parameter. Script will log the output to C:\Temp\InstallLogs\ folder.


#########################
Intune commands/settings
#########################

INSTALLATION

Install commands (User Context Examples, run in User context via Intune):
%windir%\SysNative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -command ".\install.ps1" -User
%windir%\SysNative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -command ".\install.ps1" -User -StartMenuFolder 'your StartMenu Subfolder' -Log

Uninstall commands (User Context Examples, run in User context via Intune):
%windir%\SysNative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -command ".\uninstall.ps1" -User
%windir%\SysNative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -command ".\uninstall.ps1" -User -StartMenuFolder 'your StartMenu Subfolder' -Log

Install commands (Device Context Examples, run in System context via Intune):
%windir%\SysNative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -command ".\install.ps1" -Device
%windir%\SysNative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -command ".\install.ps1" -Device -StartMenuFolder 'your StartMenu Subfolder' -Log

Uninstall commands (Device Context Examples, run in System context via Intune):
%windir%\SysNative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -command ".\uninstall.ps1" -Device
%windir%\SysNative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -command ".\uninstall.ps1" -Device -StartMenuFolder 'your StartMenu Subfolder' -Log

DETECTION

Look for files that exist. Enter all shortcuts that get placed via this installation (so if you place multiple, add multiple detection lines).

(User context installation):
File C:\Users\%username%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\yourshortcut.lnk (if you do not use the Subfolder option)
File C:\Users\%username%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\your StartMenu Subfolder\yourshortcut.lnk (if you use the Subfolder option)

(Device context installation):
File C:\ProgramData\Microsoft\Windows\Start Menu\Programs\yourshortcut.lnk (if you do not use the Subfolder option)
File C:\ProgramData\Microsoft\Windows\Start Menu\Programs\your StartMenu Subfolder\yourshortcut.lnk (if you use the Subfolder option)


###########################
Template/Example variables
###########################
I have made an example .intunewin with the files in the template so you can test its workings. 
The .intunewin contains the _source folder including the example files in the "_source\Files" folder. 
