#Define Parameters used for uninstallation
#Use package names 'AfvalRIS MCS', 'AfvalRIS MCS Test', 'AfvalRIS KCC' or 'AfvalRIS KCC Test'
param ($PackageName)

#Set dateStamp variable and Start-Transcipt for uninstallation
$dateStamp = Get-Date -Format "yyyyMMddHHmm"
Start-Transcript -Path "C:\Temp\InstallLogs\$PackageName-uninst-$dateStamp.log" -Force

try {
    #Define other variables for uninstallation
    Write-Host "Defining variables for uninstallation of $PackageName..."
    $scriptPath = (Get-Variable MyInvocation -Scope Script).Value.MyCommand.Path
    $dir = Split-Path $scriptpath
    $packageFilePath = "$dir\Files\"
    $packageFileFilter = "$PackageName" + "." + "*"
    $packageFiles = Get-ChildItem -Path $packageFilePath -Filter $PackageFileFilter
   
    $fileInstallPath = "$env:APPDATA\remoteapps"
    $startMenuPath = "$ENV:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\AfvalRIS\"
    $icoFile = Get-ChildItem -Path $packageFilePath -Filter "$PackageName.ico" 
    $rdpFile = Get-ChildItem -Path $packageFilePath -Filter "$PackageName.rdp"
    $icoFileName = $icoFile.Name
    $rdpFileName = $rdpFile.Name

    ##########################################################################
    #Remove StartMenu entry & AfvalRIS folder when it's completely empty
    ##########################################################################
    Write-Host "Removing StartMenu entries..."

    #Remove package shortcut .lnk from StartMenu if it exists...
    If (Test-Path "$startMenuPath\$packageName.lnk") {
        Write-Host "Removing $packageName.lnk from $startMenuPath..."
        Remove-Item "$startMenuPath\$packageName.lnk" -Force | Out-Null
    }
    else {
        Write-Host "StartMenu entry not found. Nothing to delete..."
    }

    #Remove StartMenu folder when there's nothing in it...
    $checkStartMenuItems = Get-ChildItem -Path $startMenuPath
    If (!($checkStartMenuItems)) {
        Write-Host "No items found in StartMenu folder. Deleting $startMenuPath as well.."
        Remove-Item $startMenuPath | Out-Null
    }
    else {
        Write-Host "Other items found in $startMenuPath. Not deleting folder..."
    }

    ###################################################################################
    #Remove ICO & RDP files, as well as the %APPDATA%\AfvalRIS folder when it's empty
    ###################################################################################
    Write-Host "Removing installed files..."

    #Remove .ico from %appdata%\AfvalRIS folder
    If (Test-Path "$fileInstallPath\$icoFileName") {
        Write-Host "Removing $icoFileName from $fileInstallPath..." 
        Remove-Item "$fileInstallPath\$icoFileName" -Force | Out-Null
    }
    else {
        Write-Host "$icoFileName not found. Nothing to delete..."
    }

    #Remove .rdp from %appdata%\AfvalRIS folder
    If (Test-Path "$fileInstallPath\$rdpFileName") {
        Write-Host "Removing $rdpFileName from $fileInstallPath..."
        Remove-Item "$fileInstallPath\$rdpFileName" -Force | Out-Null
    }
    else {
        Write-Host "$rdpFileName not found. Nothing to delete..."
    }

    #Remove %appdata%\AfvalRIS folder when it's empty
    $checkFolderItems = Get-ChildItem -Path $fileInstallPath
    If (!($checkFolderItems)) {
        Write-Host "No items found in install folder. Deleting $fileInstallPath as well.."
        Remove-Item $fileInstallPath | Out-Null
    }
    else {
        Write-Host "Other items found in $fileInstallPath. Not deleting folder..."
    }

    #############################################################################################
    #Check if all files are deleted correctly and then delete the regkey for Intune detection
    #############################################################################################
    $checkInstallation = @(
      [PsCustomObject] @{ Source = (Test-Path "$fileInstallPath\$icoFileName"); }
      [PsCustomObject] @{ Source = (Test-Path "$fileInstallPath\$rdpFileName"); }
      [PsCustomObject] @{ Source = (Test-Path "$startMenuPath\$PackageName.lnk"); }
    )
    if (($checkInstallation.Source) -contains $true){
        Write-Host "Not everything uninstalled correctly. Intune detection file will not be deleted."
    }
    else {
        Write-Host "Everything uninstalled correctly. Deleting Intune detection key..."
        Remove-ItemProperty -Path "HKCU:\Software\AfvalRIS" -Name $PackageName        
        Write-Host "Script ran successfully. Ending script..."
    }
}
Catch {
    Write-Error $_
}
Stop-Transcript