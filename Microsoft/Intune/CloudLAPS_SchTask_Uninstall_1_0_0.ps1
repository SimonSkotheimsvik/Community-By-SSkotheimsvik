    <#
.SYNOPSIS
    Script to uninstall CloudLAPS solution for environments not licensed for Proactive Remediations where the solution has been added as a Scheduled task.

.DESCRIPTION
    This script will check if the scheduled task exists and then delete it. The script will also remove the folder holding the script for the scheduled
    task and delete the old local cloudlaps administrator account.
    
.NOTES
    FileName:    CloudLAPS_SchTask_Uninstall.ps1
    Author:      Simon Skotheimsvik
    Contact:     @SSkotheimsvik
    Info:        https://skotheimsvik.no/migrating-cloud-laps-to-the-new-windows-laps
    Created:     2024.01.09
    Updated:     2024.01.09

    Version history:
    1.0.0 - (2024.01.09) Script created
 
    #>

#region Variables
$scheduledTaskName = "CloudLAPS Rotation"
$folderPath = "C:\ProgramData\CloudLAPS Client"
$userAccount = "LocalAdmin"
#endregion Variables

#region Scheduled Task
$scheduledTask = Get-ScheduledTask -TaskName $scheduledTaskName -ErrorAction SilentlyContinue

if ($scheduledTask -ne $null) {
    # Delete the scheduled task
    Unregister-ScheduledTask -TaskName $scheduledTaskName -Confirm:$false
    Write-Host "Scheduled task '$scheduledTaskName' deleted."
} else {
    Write-Host "Scheduled task '$scheduledTaskName' not found."
}
#endregion Scheduled Task


#region Script and folder
if (Test-Path $folderPath -PathType Container) {
    Remove-Item -Path $folderPath -Recurse -Force
    Write-Host "Folder '$folderPath' deleted."
} else {
    Write-Host "Folder '$folderPath' not found."
}
#endregion Script and folder


#region Local Administrator account
$userExists = Get-LocalUser -Name $userAccount -ErrorAction SilentlyContinue

if ($userExists -ne $null) {
    Remove-LocalUser -Name $userAccount -Confirm:$false
    Write-Host "User account '$userAccount' deleted."
} else {
    Write-Host "User account '$userAccount' not found."
}
#endregion Local Administrator account
