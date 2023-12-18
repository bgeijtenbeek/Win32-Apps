<#
	.SYNOPSIS
		Install Open Text and True Type Fonts
	
	.DESCRIPTION
		This script will install OTF and TTF fonts that exist in the same directory as the script.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2021 v5.8.187
		Created on:   	6/24/2021 9:36 AM
		Created by:   	Mick Pletcher
		Filename:     	InstallFonts.ps1
		===========================================================================
#>

<#
	.SYNOPSIS
		Install the font
	
	.DESCRIPTION
		This function will attempt to install the font by copying it to the c:\windows\fonts directory and then registering it in the registry. This also outputs the status of each step for easy tracking. 
	
	.PARAMETER FontFile
		Name of the Font File to install
	
	.EXAMPLE
				PS C:\> Install-Font -FontFile $value1
	
	.NOTES
		Additional information about the function.
#>

param(
     [Parameter()]
     [switch]$Log,

	 [Parameter()]
     [string]$CustomRegKey,

	 [Parameter(Mandatory=$true)]
     [string]$CustomRegItem
 )

If ($Log.IsPresent) {
    $PackageName = "FontInstaller"
    $dateStamp = Get-Date -Format "yyyyMMddHHmm"
    Start-Transcript -Path "C:\Temp\InstallLogs\$PackageName-uninst-$dateStamp.log" -Force
}

function Uninstall-Font {
	param
	(
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.IO.FileInfo]$FontFile
	)
	
	#Get Font Name from the File's Extended Attributes
	$oShell = new-object -com shell.application
	$Folder = $oShell.namespace($FontFile.DirectoryName)
	$Item = $Folder.Items().Item($FontFile.Name)
	$FontName = $Folder.GetDetailsOf($Item, 21)
	try {
		switch ($FontFile.Extension) {
			".ttf" {$FontName = $FontName + [char]32 + '(TrueType)'}
			".otf" {$FontName = $FontName + [char]32 + '(OpenType)'}
		}

		#Test if font registry entry exists and remove if so
		If ((Get-ItemProperty -Name $FontName -Path "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue)) {
			#Test if the entry matches the font file name
			If ((Get-ItemPropertyValue -Name $FontName -Path "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts") -eq $FontFile.Name) {
				$RemoveKey = $true
				Write-Host ('Removing' + [char]32 + $FontName + [char]32 + 'from the registry.....') -NoNewline
				Remove-ItemProperty -Name $FontName -Path "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -Force
				If (!(Get-ItemProperty -Name $FontName -Path "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue)) {
					Write-Host ('Success') -ForegroundColor Yellow
				}
				else {
					Write-Host ('Failed') -ForegroundColor Red
				}
				$RemoveKey = $false
			} 
			else {
				Write-Host ('Failed') -ForegroundColor Red
				Write-Host "Property value does not match."
			}
		}
		else {
			Write-Host ('Failed') -ForegroundColor Red
			Write-Host "Font not found in Registry."
		}

		#Test if font is present in C:\Windows\Fonts folder and remove if so
		$Remove = $true
		$FontFileName = $FontFile.Name
		Write-Host ('Removing' + [char]32 + $FontFile.Name + '.....') -NoNewline
		If ((Test-Path "C:\Windows\Fonts\$FontFileName") -eq $true) {
			Remove-Item -Path "C:\Windows\Fonts\$FontFileName" -Force
			If ((Test-Path "C:\Windows\Fonts\$FontFileName") -eq $false) {
				Write-Host ('Success') -Foreground Yellow
			}
			else {
				Write-Host ('Failed') -ForegroundColor Red
			}

		} else {
			Write-Host ('Failed') -ForegroundColor Red
		}
		$Remove = $false

	} catch {
		If ($Remove -eq $true) {
			Write-Host ('Failed') -ForegroundColor Red
			$Remove = $false
		}
		If ($RemoveKey -eq $true) {
			Write-Host ('Failed') -ForegroundColor Red
			$RemoveKey = $false
		}
		write-warning $_.exception.message
	}
	Write-Host
}

if ($CustomRegKey) {
	Write-Host "Custom detection regkey parameter detected. Set to 'HKLM:\SOFTWARE\$CustomRegKey'"
	$CustomRegKeyPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\$CustomRegKey"
}
else {
	Write-Host "Custom detection regkey parameter not detected. Using default 'HKLM:\SOFTWARE\CustomIntuneDetection'"
	$CustomRegKey = "CustomIntuneDetection"
	$CustomRegKeyPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\$CustomRegKey"
}
if ($CustomRegItem) {
	Write-Host "Custom detection regkey-item parameter detected. Set to '$CustomRegItem'"
}

#Get a list of all font files relative to this script and parse through the list
foreach ($FontItem in (Get-ChildItem -Path $PSScriptRoot\Fonts -Recurse | Where-Object {
			($_.Name -like '*.ttf') -or ($_.Name -like '*.OTF')
		})) {
	Uninstall-Font -FontFile $FontItem
}

#Change custom regkey value for Intune detection
If ((Get-Item -Path $CustomRegKeyPath).GetValue($CustomRegItem)) {
	Remove-ItemProperty -Name $CustomRegItem -Path $CustomRegKeyPath -Force
}
else {
	Write-Host "Warning: '$CustomRegKeyPath' item '$CustomRegItem' not found. Nothing to remove for Intune detection."
}

#End log transcript when parameter is present
If ($Log.IsPresent) {
    Stop-Transcript
}