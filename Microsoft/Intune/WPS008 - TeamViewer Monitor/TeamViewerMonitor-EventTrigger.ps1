<#
    .SYNOPSIS
    This script adds a scheduled task which checks if TeamViewer has terminated and starts the process again.

    .DESCRIPTION
    This script adds a scheduled task which checks for Event ID 4689 in the Security log. If the event is triggered by TeamViewer.exe, the script starts the TeamViewer process again.
    The scheduled task is set to run as the current user to ensure TeamViewer Host is running as the user. 

    .NOTES
    Author:     Simon Skotheimsvik
    Filename:   TeamViewerMonitor-EventTrigger.ps1
    Info:       https://skotheimsvik.no
    Versions:
            1.0.0 - 11.09.2024 - Initial Release, Simon Skotheimsvik
            1.0.1 - 12.09.2024 - Changed to Event Trigger, Simon Skotheimsvik
#>

#region Variables
$taskName = "TeamViewerMonitor"
$tempPath = [System.IO.Path]::GetTempPath()
$xmlFilePath = "$tempPath" + "TeamViewerMonitor.xml"
$installDate = Get-Date -Format "yyyy-MM-dd"
#endregion

#region Create XML Content
# Create the XML content for the scheduled task
$xmlContent = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>2024-09-11T23:45:36.3491732</Date>
    <Author>Simon Does: skotheimsvik.no</Author>
    <Description>This is a routine from SimonDoes to ensure TeamViewer Host is running on the system. `nInstalled on $installDate by Intune.</Description>
    <URI>\Event Viewer Tasks\Security_Microsoft-Windows-Security-Auditing_4689_$($taskName)</URI>
  </RegistrationInfo>
  <Triggers>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>&lt;QueryList&gt;&lt;Query Id="0" Path="Security"&gt;&lt;Select Path="Security"&gt;*[System[Provider[@Name='Microsoft-Windows-Security-Auditing'] and (EventID=4689)]]and
    *[EventData[(Data='C:\Program Files (x86)\TeamViewer\TeamViewer.exe')]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
    </EventTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <GroupId>S-1-5-32-545</GroupId>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>TeamViewer.exe</Command>
      <WorkingDirectory>C:\Program Files (x86)\TeamViewer\</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
"@
#endregion

#region Write XML Content to File
# Write the XML content to the file
Set-Content -Path $xmlFilePath -Value $xmlContent
#endregion

#region Register Scheduled Task from XML
# Check if the scheduled task exists and delete it if it does
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($taskExists) {
  Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
  Write-Output "Scheduled task '$taskName' deleted."
}

# Register the scheduled task from the XML file
Register-ScheduledTask -TaskName $taskName -Xml (Get-Content -Path $xmlFilePath -Raw)

Write-Output "Scheduled task '$taskName' created successfully from XML."
#endregion

#region Clean Up
# Remove the XML file after the task is registered
Remove-Item -Path $xmlFilePath -Force
Write-Output "Temporary XML file '$xmlFilePath' deleted."
#endregion