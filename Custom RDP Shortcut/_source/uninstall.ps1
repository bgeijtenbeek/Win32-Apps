<#
.DESCRIPTION
 Script connects to MsGraph and then fetches all registered AutoPilot Device info (more than the default export function from within Intune). It then writes it to a .csv file.
.PARAMETER <inputfile>
When used, this parameter will allow you to import a .txt file containing pre-selected serial numbers. Should contain the entire path & filename.
.PARAMETER <outputfile>
When used, this parameter will allow for changing the default export path & filename. 
.PARAMETER <Log>
Switch that, when added to installation command, will write a log/transcript of the process.
.INPUTS
Import pre-selected serial numbers so script will check only these. Should be a .txt file with every serial number on its own line. Use the inputFile parameter to add.
.OUTPUTS
Export file (.csv) - default location C:\Temp\AutoPilot-Device-Export-$dateStamp.csv (or custom when outputFile parameter is used)
Log file (.log) - will write the transcript of the script to C:\Temp\AutoPilot-Device-Export-$dateStamp.log (when Log parameter is used)
.NOTES
  Version:        1.0
  Author:         bgeijtenbeek
  Creation Date:  04-Nov-2023
  Purpose/Change: Regular export from Intune doesn't contain all the information I require such as groupTag, AssignedUser, etc.
  Prerequisites: Installed powershell modules:

    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module WindowsAutopilotIntune -MinimumVersion 5.4.0 -Force
    Install-Module Microsoft.Graph.Groups -Force
    Install-Module Microsoft.Graph.Authentication -Force
    Install-Module Microsoft.Graph.Identity.DirectoryManagement -Force

    Import-Module WindowsAutopilotIntune -MinimumVersion 5.4
    Import-Module Microsoft.Graph.Groups
    Import-Module Microsoft.Graph.Authentication
    Import-Module Microsoft.Graph.Identity.DirectoryManagement

.EXAMPLE
.\ExtendedApDeviceExport.ps1 -User 
.\ExtendedApDeviceExport.ps1 -inputFile 'C:\location\to\inputfile.txt' -outputFile 'C:\location\to\exportfile.csv' -Log
#>

param(

    [Parameter()]
    [switch]$User,

    [Parameter()]
    [switch]$Device,

    [Parameter()]
    [string]$StartMenuFolder,

    [Parameter()]
    [switch]$DesktopShortcut,

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

    if ($User.IsPresent) {
        Write-Host "User context uninstall switch found. Looking for shortcuts in user context."
        #Define User context uninstallation variables
        If ($StartMenuFolder) {
            #If custom StartMenuFolder parameter was used,
            #Set variable for custom Deploy folder
            $fileDeployFolder = "$env:APPDATA\$StartMenuFolder"
            #Set variable for custom StartMenu Folder
            $startMenuPath = "$ENV:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\$StartMenuFolder\" 
        }
        else {
            #If custom StartMenuFolder parameter was NOT used,
            #Set variable for default Deploy folder
            $fileDeployFolder = "$env:APPDATA\RDP Files\"
            #Set variable for default StartMenu folder
            $startMenuPath = "$ENV:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\" 
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
            Write-Host "Other items found in $fileInstallPath. Not deleting folder..."
        }
    }

    elseif ($Device.IsPresent) {
        Write-Host "Uninstalling shortcuts in Device context."
    }

    else {
        Write-Host "No uninstall context found. Not uninstalling anything now."
    }
}

Catch {
    Write-Error $_
}

If($Log.IsPresent) {
    Stop-Transcript
}