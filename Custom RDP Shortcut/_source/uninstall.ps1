<#
.DESCRIPTION
Script removes the StartMenu Shortcuts and local install files that were installed previously via the install.ps1 script.
.PARAMETER <User>
When used, will remove files and shortcuts from the user APPDATA folder.
.PARAMETER <Device>
When used, will remove files and shortcuts from the device ProgramData folder.
.PARAMETER <StartMenuFolder>
When used, will place the shortcuts in a new or existing StartMenu subfolder.
.PARAMETER <Log>
Switch that, when added to installation command, will write a log/transcript of the process.
.OUTPUTS
Log file (.log) - will write the transcript of the script to C:\Temp\InstallLogs\RdpShortcut-inst-$dateStamp.log (when Log parameter is used)
.NOTES
  Version:        1.0
  Author:         bgeijtenbeek
  Creation Date:  17-Nov-2023
  Purpose/Change: (Bulk) add shortcuts to .rdp files in StartMenu
.EXAMPLE
.\install.ps1 -User 
.\install.ps1 -Device -StartMenuFolder 'yourFolderName' -Log 
#>

param(

    [Parameter()]
    [switch]$User,

    [Parameter()]
    [switch]$Device,

    [Parameter()]
    [string]$StartMenuFolder,

    [Parameter()]
    [switch]$Log

 )

If($Log.IsPresent) {
    #Set dateStamp variable and Start-Transcipt for uninstallation
    $dateStamp = Get-Date -Format "yyyyMMddHHmm"
    Start-Transcript -Path "C:\Temp\InstallLogs\RdpShortcut-uninst-$dateStamp.log" -Force
}

try {    
    #Define path for .rdp & .ico files (for later in the foreach loop)
    $scriptPath = (Get-Variable MyInvocation -Scope Script).Value.MyCommand.Path
    $dir = Split-Path $scriptpath
    $packageFilePath = "$dir\Files\"
    #Get .rdp files (for later in the foreach loop)
    $packageRdpFiles = @(Get-ChildItem -Path "$packageFilePath" -Filter "*.rdp")

    #########################################################################
    #Set variables that depend on installation context
    #########################################################################
    if ($User.IsPresent) {
        Write-Host "User context uninstall switch found. Unnstalling shortcuts in user context."
        #Define User context installation variables
        If ($StartMenuFolder) {
            Write-Host "Custom StartMenu parameter data found. Using custom deploy- and install-folders."
            #If custom StartMenuFolder parameter was used,
            #Set variable for custom Deploy folder
            $fileDeployFolder = "$ENV:USERPROFILE\AppData\Roaming\$StartMenuFolder"
            #Set variable for custom StartMenu Folder
            $startMenuPath = "$ENV:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\$StartMenuFolder\" 
        }
        else {
            Write-Host "No Custom StartMenu parameter data found. Using default deploy- and install-folders."
            #If custom StartMenuFolder parameter was NOT used,
            #Set variable for default Deploy folder
            $fileDeployFolder = "$ENV:APPDATA\RDP Files\"
            #Set variable for default StartMenu folder
            $startMenuPath = "$ENV:APPDATA\Microsoft\Windows\Start Menu\Programs\" 
        }
    }
    elseif ($Device.IsPresent) {
        Write-Host "Device context uninstall switch found. Unnstalling shortcuts in device context."
        #Define User context installation variables
        If ($StartMenuFolder) {
            Write-Host "Custom StartMenu parameter data found. Using custom deploy- and install-folders."
            #If custom StartMenuFolder parameter was used,
            #Set variable for custom Deploy folder
            $fileDeployFolder = "$ENV:ProgramData\$StartMenuFolder"
            #Set variable for custom StartMenu Folder
            $startMenuPath = "$ENV:ProgramData\Microsoft\Windows\Start Menu\Programs\$StartMenuFolder\" 
        }
        else {
            Write-Host "No Custom StartMenu parameter data found. Using default deploy- and install-folders."
            #If custom StartMenuFolder parameter was NOT used,
            #Set variable for default Deploy folder
            $fileDeployFolder = "$ENV:ProgramData\RDP Files\"
            #Set variable for default StartMenu folder
            $startMenuPath = "$ENV:ProgramData\Microsoft\Windows\Start Menu\Programs\" 
        }
    }
    else {
        Write-Host "No uninstallation context parameter passed, the process cannot continue. Please use uninstallation context parameter."
        Write-Host "Exiting script."
        if ($Log.IsPresent) {
            Stop-Transcript
        }
        Exit 2468
    }

    ##########################################################################
    #Remove installed files from $fileDeployFolder and $startMenuPath
    ##########################################################################
    Write-Host "Start removing files and shortcuts.."
    foreach ($packageRdpFile in $packageRdpFiles) {

        #Get the filename for specific .rdp
        $shortcutName = ($packageRdpFile.Name) -replace ".{4}$" #drop last 4 chars

        #Try to find the matching StartMenu .lnk and remove the file
        If (Test-Path "$startMenuPath\$shortcutName.lnk") {
            Remove-Item "$startMenuPath\$shortcutName.lnk" -Force | Out-Null
            Write-Host "Removed $shortcutName.lnk from StartMenu location $startMenuPath"
        } 
        else {
            Write-Host "$shortcutName.lnk not found in StartMenu location $startMenuPath. Nothing to remove."
        }      

        #Try to find the matching source .rdp and remove the file
        If (Test-Path "$fileDeployFolder\$shortcutName.rdp") {
            Remove-Item "$fileDeployFolder\$shortcutName.rdp" -Force | Out-Null
            Write-Host "Removed $shortcutName.rdp from location $fileDeployFolder"
        } 
        else {
            Write-Host "$shortcutName.rdp not found in location $fileDeployFolder. Nothing to remove."
        } 
        
        #Try to find the matching source .ico and remove the file
        If (Test-Path "$fileDeployFolder\$shortcutName.ico") {
            Remove-Item "$fileDeployFolder\$shortcutName.ico" -Force | Out-Null
            Write-Host "Removed $shortcutName.ico from location $fileDeployFolder"
        } 
        else {
            Write-Host "$shortcutName.ico not found in location $fileDeployFolder. Nothing to remove."
        }     
    }

    ##########################################################################
    #Remove $fileDeployFolder and $startMenuPath as well when they are empty
    ##########################################################################

    #Look for child-items in the $startMenuPath and delete it when there are none left
    $checkStartMenuItems = Get-ChildItem -Path $startMenuPath
    If (!($checkStartMenuItems)) {
        Write-Host "No items left in StartMenu folder. Deleting $startMenuPath as well.."
        Remove-Item $startMenuPath | Out-Null
    }
    else {
        Write-Host "Other items found in $startMenuPath. Not deleting folder..."
    }
    
    #Look for child-items in the $fileDeployFolder and delete it when there are none left
    $checkFolderItems = Get-ChildItem -Path $fileDeployFolder
    If (!($checkFolderItems)) {
        Write-Host "No items left in install folder. Deleting $fileDeployFolder as well.."
        Remove-Item $fileDeployFolder | Out-Null
    }
    else {
        Write-Host "Other items found in $fileDeployFolder. Not deleting folder..."
    }
}

Catch {
    Write-Error $_
}

If($Log.IsPresent) {
    Stop-Transcript
}