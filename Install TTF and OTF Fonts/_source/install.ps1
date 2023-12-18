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
    Start-Transcript -Path "C:\Temp\InstallLogs\$PackageName-inst-$dateStamp.log" -Force
}

function Install-Font {
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
		$Copy = $true
		Write-Host ('Copying' + [char]32 + $FontFile.Name + '.....') -NoNewline
		Copy-Item -Path $fontFile.FullName -Destination ("C:\Windows\Fonts\" + $FontFile.Name) -Force
		#Test if font is copied over
		If ((Test-Path ("C:\Windows\Fonts\" + $FontFile.Name)) -eq $true) {
			Write-Host ('Success') -Foreground Yellow
		} else {
			Write-Host ('Failed') -ForegroundColor Red
		}
		$Copy = $false
		#Test if font registry entry exists
		If ((Get-ItemProperty -Name $FontName -Path "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue)) {
			#Test if the entry matches the font file name
			If ((Get-ItemPropertyValue -Name $FontName -Path "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts") -eq $FontFile.Name) {
				Write-Host ('Adding' + [char]32 + $FontName + [char]32 + 'to the registry.....') -NoNewline
				Write-Host ('Success') -ForegroundColor Yellow
			} else {
				$AddKey = $true
				Remove-ItemProperty -Name $FontName -Path "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -Force
				Write-Host ('Adding' + [char]32 + $FontName + [char]32 + 'to the registry.....') -NoNewline
				New-ItemProperty -Name $FontName -Path "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $FontFile.Name -Force -ErrorAction SilentlyContinue | Out-Null
				If ((Get-ItemPropertyValue -Name $FontName -Path "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts") -eq $FontFile.Name) {
					Write-Host ('Success') -ForegroundColor Yellow
				} else {
					Write-Host ('Failed') -ForegroundColor Red
				}
				$AddKey = $false
			}
		} else {
			$AddKey = $true
			Write-Host ('Adding' + [char]32 + $FontName + [char]32 + 'to the registry.....') -NoNewline
			New-ItemProperty -Name $FontName -Path "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $FontFile.Name -Force -ErrorAction SilentlyContinue | Out-Null
			If ((Get-ItemPropertyValue -Name $FontName -Path "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts") -eq $FontFile.Name) {
				Write-Host ('Success') -ForegroundColor Yellow
			} else {
				Write-Host ('Failed') -ForegroundColor Red
			}
			$AddKey = $false
		}
		
	} catch {
		If ($Copy -eq $true) {
			Write-Host ('Failed') -ForegroundColor Red
			$Copy = $false
		}
		If ($AddKey -eq $true) {
			Write-Host ('Failed') -ForegroundColor Red
			$AddKey = $false
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
	Write-Host "Custom detection regkey-item parameter detected. Set to '$CustomRegItem' with value 'Installed'"
}

#Get a list of all font files relative to this script and parse through the list
foreach ($FontItem in (Get-ChildItem -Path $PSScriptRoot\Fonts -Recurse | Where-Object {
			($_.Name -like '*.ttf') -or ($_.Name -like '*.OTF')
		})) {
	Install-Font -FontFile $FontItem
}

#Write custom regkey for Intune detection
if (!(Test-Path $CustomRegKeyPath)) {
	New-Item -Name "$CustomRegKey" -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE" -Force | Out-Null
	New-ItemProperty -Name $CustomRegItem -Path $CustomRegKeyPath -PropertyType string -Value "Installed" -Force -ErrorAction SilentlyContinue | Out-Null
	Write-Host "Created Intune detection registry item at $CustomRegKeyPath, item '$CustomRegItem'"
}
else {
	New-ItemProperty -Name $CustomRegItem -Path $CustomRegKeyPath -PropertyType string -Value "Installed" -Force -ErrorAction SilentlyContinue | Out-Null
	Write-Host "Created Intune detection registry item at $CustomRegKeyPath, item '$CustomRegItem'"
}

If ($Log.IsPresent) {
    Stop-Transcript
}