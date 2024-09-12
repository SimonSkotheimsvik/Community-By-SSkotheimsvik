<#
    .SYNOPSIS
    This script adds a scheduled task which checks if TeamViewer is running. If TeamViewer is not running, the script starts the TeamViewer process and logs an event to the Application Log.

    .DESCRIPTION
    This script adds a scheduled task which checks if TeamViewer Host is running. If TeamViewer is not running, the script starts the TeamViewer process and logs an event to the Application Log.
    The script utilizes the PSInvoker tool from MSEndpointMgr to run the PowerShell script as a scheduled task without having av PowerShell window displaying for the end user.
    The scheduled task is set to run at logon as the current user to ensure TeamViewer Host is running as the user. 

    .NOTES
    Author:     Simon Skotheimsvik
    Filename:   TeamViewerMonitor-TimeTrigger.ps1
    Info:       https://skotheimsvik.no
    Reference:  https://github.com/MSEndpointMgr/PSInvoker/tree/master
    Versions:
            1.0.0 - 11.09.2024 - Initial Release, Simon Skotheimsvik
#>



#region Variables
$taskName = "TeamViewerMonitor"
$SimonDoesPath = "C:\Program Files\SimonDoes"
$xmlFilePath = "$SimonDoesPath\TeamViewerMonitor.xml"
$scriptPath = "$SimonDoesPath\CheckStartAndLogTeamViewer.ps1"
$zipFilePath = "$SimonDoesPath\PSInvoker.zip"
$installDate = Get-Date -Format "yyyy-MM-dd"
$Interval = 15  #Interval for scheduled task in minutes
#endregion

#region Download and Extract PSInvoker from MSEndpointMGR GitHub
# Define the URL and the destination path for the ZIP file
$zipUrl = "https://github.com/MSEndpointMgr/PSInvoker/releases/download/1.0.1/PSInvoker.zip"

# Download the ZIP file
Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath

# Ensure the script directory exists
if (-not (Test-Path $SimonDoesPath)) {
    New-Item -Path $SimonDoesPath -ItemType Directory
}

# Extract the ZIP file to the script directory
Expand-Archive -Path $zipFilePath -DestinationPath $SimonDoesPath -Force

# Remove the ZIP file after extraction
Remove-Item -Path $zipFilePath
#endregion


#region Create PowerShell Script
# Create the PowerShell script to check and log TeamViewer status
$scriptContent = @'
$processName = "TeamViewer"
$teamViewerPath = "C:\Program Files (x86)\TeamViewer\TeamViewer.exe"

if (Test-Path $teamViewerPath) {
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($process -eq $null) {
        # Log an event to the Application Log
        if (-not (Get-EventLog -LogName Application -Source "TeamViewerMonitor" -ErrorAction SilentlyContinue)) {
            New-EventLog -LogName Application -Source "TeamViewerMonitor"
        }
        Write-EventLog -LogName Application -Source "TeamViewerMonitor" -EventId 1001 -EntryType Information -Message "TeamViewer has stopped and is being restarted by TeamViewerMonitor from SimonDoes."

        # Start TeamViewer
        Start-Process $teamViewerPath
    }
} else {
    # Log an event if TeamViewer is not installed
    if (-not (Get-EventLog -LogName Application -Source "TeamViewerMonitor" -ErrorAction SilentlyContinue)) {
        New-EventLog -LogName Application -Source "TeamViewerMonitor"
    }
    Write-EventLog -LogName Application -Source "TeamViewerMonitor" -EventId 1002 -EntryType Warning -Message "TeamViewer is not installed on this system."
}
'@
#endregion

#region Ensure Script Directory Exists
# Ensure the script directory exists
if (-not (Test-Path "C:\Program Files\SimonDoes")) {
    New-Item -Path "C:\Program Files\SimonDoes" -ItemType Directory
}
#endregion

#region Write Script Content to File
# Write the script content to the file
Set-Content -Path $scriptPath -Value $scriptContent
#endregion

#region Create XML Content
# Create the XML content for the scheduled task
$xmlContent = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Author>5337D3DB-D8D3-4\WDAGUtilityAccount</Author>
    <Description>This is a routine from SimonDoes to ensure TeamViewer host is running on the system.
Installed on $installDate by Intune.</Description>
    <URI>\TeamViewerMonitor</URI>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Repetition>
        <Interval>PT$($Interval)M</Interval>
        <StopAtDurationEnd>false</StopAtDurationEnd>
      </Repetition>
      <Enabled>true</Enabled>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <GroupId>S-1-5-32-545</GroupId>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>PSInvoker.exe</Command>
      <Arguments>CheckStartAndLogTeamViewer.ps1 --ExecutionPolicy Bypass</Arguments>
      <WorkingDirectory>$SimonDoesPath</WorkingDirectory>
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