    <#
.SYNOPSIS
    Script to remove CloudLAPS EventLog.

.DESCRIPTION
    This script will check if the Event Log named "CloudLAPS-Client" exists and then delete it.
    
.NOTES
    FileName:    CloudLAPS_EventLog_Remocal.ps1
    Author:      Simon Skotheimsvik
    Contact:     @SSkotheimsvik
    Info:        https://skotheimsvik.no/migrating-cloud-laps-to-the-new-windows-laps
    Created:     2024.01.11
    Updated:     2024.01.11

    Version history:
    1.0.0 - (2024.01.11) Script created
 
    #>

#region Variables
$eventLogName = "CloudLAPS-Client"
#endregion Variables

#region EventLog
if (Get-EventLog -LogName $eventLogName -ErrorAction SilentlyContinue) {
    # If it exists, delete the EventLog
    Remove-EventLog -LogName $eventLogName
    Write-Host "EventLog '$eventLogName' has been deleted."
} else {
    Write-Host "EventLog '$eventLogName' does not exist."
}
#endregion EventLog