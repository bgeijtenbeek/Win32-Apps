<#
.DESCRIPTION
Script copies .rdp and .ico files to local folder and then places shortcut to them in the StartMenu.
.PARAMETER <User>
When used, will place files and shortcuts in the user APPDATA folder.
.PARAMETER <Device>
When used, will place files and shortcuts in the device ProgramData folder.
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

    #########################################################################
    #Set variables that depend on installation context
    #########################################################################
    if ($User.IsPresent) {
        Write-Host "User context install switch found. Installing shortcuts in user context."
        #Define User context installation variables
        If ($StartMenuFolder) {
            Write-Host "Custom StartMenu parameter data found. Using custom deploy- and install-folders."
            #If custom StartMenuFolder parameter was used,
            #Set variable for custom folder to copy files to
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
        Write-Host "Device context install switch found. Installing shortcuts in device context."
        #Define User context installation variables
        If ($StartMenuFolder) {
            Write-Host "Custom StartMenu parameter data found. Using custom deploy- and install-folders."
            #If custom StartMenuFolder parameter was used,
            #Set variable for custom folder to copy files to
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
        Write-Host "No installation context parameter passed, installation cannot continue. Please use installation context parameter."
        Write-Host "Exiting script."
        if ($Log.IsPresent) {
            Stop-Transcript
        }
        Exit 2468
    }

    ###############################################################
    #Prepare folders for installation
    ###############################################################
    Write-Host "Preparing folders for installation."
    #If deployment folder does not exist, create.
    $checkDeployFolder = Test-Path $fileDeployFolder
    If (!($checkDeployFolder)) {
        New-Item -Path $fileDeployFolder -ItemType Directory -Force | Out-Null
        Write-Host "Deploy folder $fileDeployFolder did not exist. Created now."
    }
    else {
        Write-Host "Deploy folder $fileDeployFolder already exists. No creation required."
    }

    #If StartMenu folder does not exist, create.
    $checkStartMenuFolder = Test-Path $startMenuPath
    If (!($checkStartMenuFolder)) {
        New-Item -Path $startMenuPath -ItemType Directory -Force | Out-Null
        Write-Host "StartMenu folder $startMenuPath did not exist. Created now."
    }
    else {
        Write-Host "StartMenu folder $startMenuPath already exists. No creation required."
    }

    ###############################################################
    #Copy files to $fileDeployFolder and $startMenuPath 
    ###############################################################
    Write-Host "Start copying & installing shortcuts.."
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
    Write-Host "End of script."
}

Catch {
    Write-Error $_
    }

If($Log.IsPresent) {
    Stop-Transcript
}