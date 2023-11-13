#Define Parameters used for installation
#Use package names 'AfvalRIS MCS', 'AfvalRIS MCS Test', 'AfvalRIS KCC' or 'AfvalRIS KCC Test'
param ($PackageName)

#Set dateStamp variable and Start-Transcipt for installation
$dateStamp = Get-Date -Format "yyyyMMddHHmm"
Start-Transcript -Path "C:\Temp\InstallLogs\$PackageName-inst-$dateStamp.log" -Force

try {
    #Define other variables for installation
    Write-Host "Defining variables for installation of $PackageName..."
    $scriptPath = (Get-Variable MyInvocation -Scope Script).Value.MyCommand.Path
    $dir = Split-Path $scriptpath
    $packageFilePath = "$dir\Files\"
    $packageFileFilter = "$PackageName" + "." + "*"
    $packageFiles = Get-ChildItem -Path $packageFilePath -Filter $PackageFileFilter

    $fileInstallPath = "$env:APPDATA\remoteapps"
    $checkInstallFolder = Test-Path $fileInstallPath
    $startMenuPath = "$ENV:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\AfvalRIS\"
    $checkStartMenuFolder = Test-Path $startMenuPath
    $icoFile = Get-ChildItem -Path $packageFilePath -Filter "$PackageName.ico" 
    $rdpFile = Get-ChildItem -Path $packageFilePath -Filter "$PackageName.rdp"
    $icoFileName = $icoFile.Name
    $rdpFileName = $rdpFile.Name

    ###############################################################
    #Install required files to %Appdata%\AfvalRIS folder
    ###############################################################
    Write-Host "Start copying $PackageName files..."

    #If installation folder does not exist, create.
    If (!($checkInstallFolder)) {
        New-Item -Path $fileInstallPath -ItemType Directory -Force | Out-Null
        Write-Host "$fileInstallPath did not exist. Created now."
    }
    else {
        Write-Host "$fileInstallPath already exists. No creation required."
    }

    #Install the package files into installation folder
    foreach ($packageFile in $packageFiles) {
        Copy-Item $packageFile.FullName "$fileInstallPath\$($packageFile.Name)" -Force
        Write-Host "Copied $($packageFile.Name) to $fileInstallPath."
    }

    ###############################################################
    #Create StartMenu shortcuts    
    ###############################################################
    Write-Host "Creating StartMenu entries..."

    #If StartMenu folder does not exist, create.
    If (!($checkStartMenuFolder)) {
        New-Item -Path $StartMenuPath -ItemType Directory -Force | Out-Null
        Write-Host "$StartMenuPath did not exist. Created now."
    }
    else {
        Write-Host "$StartMenuPath already exists. No creation required."
    }

    #Create shortcuts in StartMenu
    Write-Host "Creating shortcut in StartMenu folder.."
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$startMenuPath\$packageName" + ".lnk")
    $Shortcut.TargetPath = "$fileInstallPath\$rdpFileName"
    $Shortcut.IconLocation = "$fileInstallPath\$icoFileName"
    $Shortcut.Save()

    #############################################################################################
    #Check if all files are written correctly and then write the .txt used for Intune detection
    #############################################################################################
    $checkInstallation = @(
      [PsCustomObject] @{ Source = (Test-Path "$fileInstallPath\$icoFileName"); }
      [PsCustomObject] @{ Source = (Test-Path "$fileInstallPath\$rdpFileName"); }
      [PsCustomObject] @{ Source = (Test-Path "$startMenuPath\$packageName.lnk"); }
    )
    if (($checkInstallation.Source) -contains $false){
        Write-Host "Not everything installed correctly. Intune detection regkey will not be created."
    }
    else {
        Write-Host "Everything installed correctly. Writing Intune detection regkey..."
        
        #Create regkey if it doesnt exist yet
        If (!(Test-Path "HKCU:\Software\AfvalRIS")) {
            New-Item –Path "HKCU:\Software\" –Name AfvalRIS 
            Write-Host "Regkey HKCU:\Software\AfvalRIS created."
        }
        Else {
            Write-Host "Regkey HKCU:\Software\AfvalRIS already exists. Not created this run."
        }

        #Create regkey value for Intune detection
        New-ItemProperty -Path "HKCU:\Software\AfvalRIS" -Name "$PackageName" -Value ”Installed”  -PropertyType "String"
        Write-Host "Script ran successfully. Ending script..."
    }
}
Catch {
    Write-Error $_
    }
Stop-Transcript