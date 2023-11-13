#$PackageName = "AfvalRIS MCS"
#$PackageName = "AfvalRIS MCS Test"
$PackageName = "AfvalRIS KCC"
#$PackageName = "AfvalRIS KCC Test"

###############################################################################################
#Define Get-LoggedOnUserSID function
###############################################################################################
Function Get-LoggedOnUserSID {
    # ref https://www.reddit.com/r/PowerShell/comments/7coamf/query_no_user_exists_for/
    $header=@('SESSIONNAME', 'USERNAME', 'ID', 'STATE', 'TYPE', 'DEVICE')
    $Sessions = query session
    [array]$ActiveSessions = $Sessions | Select -Skip 1 | Where {$_ -match "Active"}
    If ($ActiveSessions.Count -ge 1)
    {
        $LoggedOnUsers = @()
        $indexes = $header | ForEach-Object {($Sessions[0]).IndexOf(" $_")}        
        for($row=0; $row -lt $ActiveSessions.Count; $row++)
        {
            $obj=New-Object psobject
            for($i=0; $i -lt $header.Count; $i++)
            {
                $begin=$indexes[$i]
                $end=if($i -lt $header.Count-1) {$indexes[$i+1]} else {$ActiveSessions[$row].length}
                $obj | Add-Member NoteProperty $header[$i] ($ActiveSessions[$row].substring($begin, $end-$begin)).trim()
            }
            $LoggedOnUsers += $obj
        }
 
        $LoggedOnUser = $LoggedOnUsers[0]
        $LoggedOnUserSID = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\SessionData\$($LoggedOnUser.ID)" -Name LoggedOnUserSID -ErrorAction SilentlyContinue |
            Select -ExpandProperty LoggedOnUserSID
        Return $LoggedOnUserSID
    } 
}

###############################################################################################
#Get-CurrentLoggedOnUser SID and use it to detect installation key in HKU
###############################################################################################
$LoggedOnUserSID = Get-LoggedOnUserSID
 
If ($null -ne $LoggedOnUserSID) {
    
    If ($null -eq (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
        $null = New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
    }
    
    $i = Get-Item "HKU:\$LoggedOnUserSID\Software\AfvalRIS" -ErrorAction SilentlyContinue
    
    if ($null -eq $i) {
        #If Detection key does not exist. 
        "Detection key does not exist"
        Exit 1
    }

    else {
        $r = Get-ItemProperty "HKU:\$LoggedOnUserSID\Software\AfvalRIS" -Name $PackageName -ErrorAction SilentlyContinue | 
            Select -ExpandProperty $PackageName
        If ($r -ne 'Installed')
        {
            #Key exists but does not have the correct value.    
            "Detection key exists but has the wrong value."
            Exit 1
        }
        else
        {
            #Detection key found, app seems installed.
            "Detection values correct / detected"
            Exit 0   
        }
    }
}
Else
{
    #No logged on user detected so no possibility to look for a detection key in any HKU profile.
    "No logged on user detected, detection script cannot complete."
    Exit 1
}