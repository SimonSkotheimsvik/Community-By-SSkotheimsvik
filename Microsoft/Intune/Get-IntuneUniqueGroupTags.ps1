<#
.SYNOPSIS
    Script to get unique Group Tags from Autopilot devices
.DESCRIPTION
    Script to get unique Group Tags from Autopilot devices in Microsoft Intune using Microsoft Graph PowerShell SDK.
.EXAMPLE
    
.NOTES
    Author:         Simon Skotheimsvik
    Contact:        skotheimsvik.no
    Version history:
    1.0 - (09.09.2025) Script released, Simon Skotheimsvik

#>


# Install required module if not present
if (-not (Get-Module Microsoft.Graph.DeviceManagement.Enrollment -ListAvailable)) {
    Install-Module Microsoft.Graph.DeviceManagement.Enrollment -Scope CurrentUser -Force
}

Import-Module-Module Microsoft.Graph.DeviceManagement.Enrollment

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.Read.All"

# Get all Autopilot devices
$devices = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -All

# Extract and list unique Group Tags
$uniqueGroupTags = $devices | Select-Object -ExpandProperty GroupTag | Where-Object { $_ -ne $null -and $_ -ne "" } | Sort-Object -Unique

# Display results
Write-Host "Unique Group Tags in Autopilot Devices:"
$uniqueGroupTags

# Display count for each Group Tag
$groupTagCounts = $devices | Group-Object -Property GroupTag | Sort-Object Name
Write-Host "`nGroup Tag Counts:"
$groupTagCounts | ForEach-Object { Write-Host "$($_.Name): $($_.Count)" }

# Display different enrollmentstates for Autopilot devices.
$devices | Group-Object -Property EnrollmentState | Select-Object Name, Count

# Display numbers for enrollment states for each grouptag
$devices | Group-Object -Property GroupTag, EnrollmentState | Select-Object @{Name='GroupTag';Expression={$_.Values[0]}}, @{Name='EnrollmentState';Expression={$_.Values[1]}}, Count | Sort-Object GroupTag, EnrollmentState | Format-Table -AutoSize

$devices | measure

$devices[3] | fl

# Get number of devices assigned to each Autopilot profile
Import-Module Microsoft.Graph.Beta.DeviceManagement.Enrollment
$profileAssignments = @(); foreach ($profile in $profiles) { $assignedDevices = Get-MgBetaDeviceManagementWindowsAutopilotDeploymentProfileAssignedDevice -WindowsAutopilotDeploymentProfileId $profile.Id -All; $profileAssignments += [PSCustomObject]@{ ProfileName = $profile.DisplayName; DeviceCount = ($assignedDevices | Measure-Object).Count } }; $profileAssignments | Format-Table -AutoSize