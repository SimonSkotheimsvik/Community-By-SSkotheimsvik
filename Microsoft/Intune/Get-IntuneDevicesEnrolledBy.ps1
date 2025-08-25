<#
.SYNOPSIS
This scripts list all devices enrolled in Intune by a given user.

.DESCRIPTION
There is a discussion going on using DEM account with Autopilot. This script will list all devices enrolled in Intune by a given user.
Read this post for a summery: https://call4cloud.nl/using-a-dem-account-windows-autopilot-is-a-bad-idea/

.NOTES
Author:  Simon Skotheimsvik
Version:
        1.0.0 - 2025-02-25 - Initial release, Simon Skotheimsvik
#>

# Name to search for, e.g. DEM-Account or deviceuser
$Name = "kim"

# Connect to Microsoft Graph (ensure you have the necessary permissions)
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"

# Query for devices with management name containing the specified name
$devices = Get-MgDeviceManagementManagedDevice -All | Where-Object { $_.ManagedDeviceName -like "*$($Name)*" }

# Display the results
if ($devices) {
    $devices | Select-Object DeviceName, ManagedDeviceName, UserPrincipalName, OperatingSystem, OSVersion, LastSyncDateTime | Out-GridView
    Write-Host "Total devices found: $($devices.Count)"
} else {
    Write-Host "No devices found with management name containing '($Name)'"
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph