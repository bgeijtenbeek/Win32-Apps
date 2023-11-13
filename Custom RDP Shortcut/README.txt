#Gemaakt door: B. Geijtenbeek / Infradax
#Gemaakt voor: Gemeenschappelijke Regeling Cure / Cure Afvalbeheer
#Datum: 27-10-2023
#Ticket/change:

Deze package is een bundel: het bevat de installatie van alle AfvalRIS RDP shortcuts (MCS, MCS Test, KCC & KCC Test).
Bij installatie moet er een parameter -PackageName opgegeven worden. Aan de hand van deze parameter installeert & de-installeert het script de juiste shortcuts, files en registerwaardes.

Package bevat:
- Alle AfvalRIS rdp en ico files (MCS, MCS Test, KCC & KCC Test).
- Installatiescript (.ps1)
	- Kopieert ico en rdp naar folder %appdata%\remoteapps
	- Maakt in StartMenu een AfvalRIS folder aan en voegt een shortcut toe naar de rdp in %appdata%\remoteapps.
	- Schrijft een regkey weg in HKCU:\Software\AfvalRIS om de app te kunnen detecteren
- Deinstallatiescript (.ps1)
	- Haalt de detectieregkey weg uit HKCU:\Software\AfvalRIS
	- Haalt de StartMenu shortcuts weg
	- Verwijdert de .ico en .rdp in de %appdata%\remoteapps folder
	- Wanneer de StartMenu folder (AfvalRIS) en de %appdata%\remoteapps folders geen overige data meer bevatten worden deze ook meteen opgeruimd.

INTUNE SETTINGS
Icon: Meegeleverd in de package folder. (MCS heeft de gele variant, KCC de andere)
Install context: User
Install command: %windir%\SysNative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -Command ".\install_modular.ps1" -PackageName 'jouwpackagename'
Uninstall command: %windir%\SysNative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -Command ".\uninstall_modular.ps1" -PackageName 'jouwpackagename'
Voorbeeld command: %windir%\SysNative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -Command ".\install_modular.ps1" -PackageName 'AfvalRIS MCS'

PACKAGENAMES
Dit variabele is belangrijk want zonder wordt er niets geinstalleerd. De huidige beschikbare packagenames zijn:
- 'AfvalRIS MCS'
- 'AfvalRIS MCS Test'
- 'AfvalRIS KCC'
- 'AfvalRIS KCC Test'

Detection: Kies het juiste detectiescript uit, deze staat in de package folder. Let op: elke versie heeft zijn eigen detectiescript!
Run script as 32-bit process on 64-bit clients: No
Enforce script signature check and run script silently: No