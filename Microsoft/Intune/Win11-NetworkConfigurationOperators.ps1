<#
  .NOTES
  ===========================================================================
   Created on:   	02.03.2023
   Created by:   	Simon Skotheimsvik
   Filename:     	Win11-NetworkConfigurationOperators.ps1
   Info:          https://skotheimsvik.no
   Reference:     https://call4cloud.nl/2021/04/dude-wheres-my-admin/#changing
   Version:       1.0 - 02.03.2023 - Initial release
                  1.1 - 19.06.2024 - Modified based on feedback on group ID and runlevel
  ===========================================================================
  
  .DESCRIPTION
    This script adds users to the local group "Network Configuration Operators".
    Members in this group can have some administrative privileges to manage
    configuration of networking features.

    The script can be distributed through Intune and targeted to a group of
    users qualifying to get this right "AZ-Device-Role-Local Network Configuration Operators"
    The script should run under system context. It will create a local scheduled task
    running at each user logon.
   
#>

$content = @' 
$loggedonuser = Get-WMIObject -class Win32_ComputerSystem | Select-Object -ExpandProperty username 
$groupSID = “S-1-5-32-556”
Add-LocalGroupMember -SID $groupSID -Member $loggedonuser 
'@ 
 
 # create custom folder and write PS script 
$path = $(Join-Path $env:ProgramData CustomScripts) 
if (!(Test-Path $path)) 
{ 
New-Item -Path $path -ItemType Directory -Force -Confirm:$false 
} 
Out-File -FilePath $(Join-Path $env:ProgramData CustomScripts\NetworkOperatorGroup.ps1) -Encoding unicode -Force -InputObject $content -Confirm:$false 
  
# register script as scheduled task 
$Time = New-ScheduledTaskTrigger -AtLogOn 
$User = "SYSTEM" 
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ex bypass -file `"C:\ProgramData\CustomScripts\NetworkOperatorGroup.ps1`"" 
$TaskName = “AddUserToNetworkOperatorGroup”
Register-ScheduledTask -TaskName $TaskName -Trigger $Time -User $User -Action $Action -RunLevel Highest -Force 
