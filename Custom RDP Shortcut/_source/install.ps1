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
.\ExtendedApDeviceExport.ps1
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
    #Set dateStamp variable and Start-Transcipt for installation
    $dateStamp = Get-Date -Format "yyyyMMddHHmm"
    Start-Transcript -Path "C:\Temp\InstallLogs\RdpShortcut-inst-$dateStamp.log" -Force
}

try {    
    #Define path for .rdp & .ico files (for later in the foreach loop)
    $scriptPath = (Get-Variable MyInvocation -Scope Script).Value.MyCommand.Path
    $dir = Split-Path $scriptpath
    $packageFilePath = "$dir\Files\"
    #Get .rdp files (for later in the foreach loop)
    $packageRdpFiles = @(Get-ChildItem -Path "$packageFilePath" -Filter "*.rdp")

    if ($User.IsPresent) {
        Write-Host "User context install switch found. Installing shortcuts in user context."
        #Define User context installation variables
        If ($StartMenuFolder) {
            #If custom StartMenuFolder parameter was used,
            #Set variable for custom folder to copy files to
            $fileDeployFolder = "$env:APPDATA\$StartMenuFolder"
            #Set variable for custom StartMenu Folder
            $startMenuPath = "$ENV:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\$StartMenuFolder\" 
        }
        else {
            #If custom StartMenuFolder parameter was  NOT used,
            #Set variable for default folder to copy files to
            $fileDeployFolder = "$env:APPDATA\RDP Files\"
            #Set variable for no StartMenu folder
            $startMenuPath = "$ENV:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\" 
        }

        ###############################################################
        #Prepare folders for installation
        ###############################################################
        #If deployment folder does not exist, create.
        $checkDeployFolder = Test-Path $fileDeployFolder
        If (!($checkDeployFolder)) {
            New-Item -Path $fileDeployFolder -ItemType Directory -Force | Out-Null
            Write-Host "$fileDeployFolder did not exist. Created now."
        }
        else {
            Write-Host "$fileDeployFolder already exists. No creation required."
        }

        #If StartMenu folder does not exist, create.
        $checkStartMenuFolder = Test-Path $startMenuPath
        If (!($checkStartMenuFolder)) {
            New-Item -Path $startMenuPath -ItemType Directory -Force | Out-Null
            Write-Host "$startMenuPath did not exist. Created now."
        }
        else {
            Write-Host "$startMenuPath already exists. No creation required."
        }

        ###############################################################
        #Copy required files to %Appdata%\$fileDeployFolder and StartMenu shortcuts to 
        ###############################################################
        Write-Host "Start copying & installing shortcuts.."

        #Copy package .rdp & ico files into deployment folder
        foreach ($packageRdpFile in $packageRdpFiles) {
            #Copy the .rdp file
            Copy-Item $packageRdpFile.FullName "$fileDeployFolder\$($packageRdpFile.Name)" -Force
            Write-Host "Copied $($packageRdpFile.Name) to $fileDeployFolder."

            #Get the .rdp filename and remove the file extension
            $shortcutName = ($packageRdpFile.Name) -replace ".{4}$" #drop last 4 chars
            $rdpFile = Get-ChildItem -Path $packageFilePath -Filter "$shortcutName.rdp"
            $rdpFileName = $rdpFile.Name

            #Try to find the matching .ico file
            If (Test-Path "$packageFilePath\$shortcutName.ico") {
                Copy-Item "$packageFilePath\$shortcutName.ico" "$fileDeployFolder\$shortcutName.ico" -Force
                Write-Host "Matching $shortcutName.ico found. Copied to $fileDeployFolder."
                $icoFile = Get-ChildItem -Path $packageFilePath -Filter "$shortcutName.ico" -ErrorAction SilentlyContinue
                $icoFileName = $icoFile.Name
            } 
            else {
                Write-Host "No matching $shortcutName.ico found in package. Generic icon will be used."
                $icoFileName = "None"
            }      

            #Create shortcut in StartMenu
            $WshShell = New-Object -comObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut("$startMenuPath\$shortcutName" + ".lnk")
            $Shortcut.TargetPath = "$fileDeployFolder\$rdpFileName"
            if ($icofilename -ne "None") {
                $Shortcut.IconLocation = "$fileDeployFolder\$icoFileName"
            }
            $Shortcut.Save()
            Write-Host "Created $shortcutName.lnk StartMenu shortcut in $startMenuPath"
        }
    }

    elseif ($Device.IsPresent) {
        Write-Host "Installing shortcuts in Device context."
    }

    else {
        Write-Host "No install context found. Not installing anything now. Please append the installation context to the install command and try again."
    }
}

Catch {
    Write-Error $_
    }

If($Log.IsPresent) {
    Stop-Transcript
}