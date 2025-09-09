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

$devices | measure