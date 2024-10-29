<#
.SYNOPSIS
This script lists all devices that have not synced with Intune for the last 55 days.
Use this script in conjunction with the Intune cleanup process to identify devices that have not synced recently.

.DESCRIPTION
This script lists all devices that have not synced with Intune for the last 55 days. The script uses the Microsoft.Graph.Beta.DeviceManagement module to connect to Microsoft Graph and retrieve the devices. 
The script then filters the devices based on the LastSyncDateTime property and calculates the number of days since the last sync. The script outputs the devices to an Out-GridView window.

.NOTES
Author:  Simon Skotheimsvik
Version:
        1.0.0 - 2024-10-29 - Initial release, Simon Skotheimsvik
#>

# Define the threshold date (55 days ago)
$thresholdDate = (Get-Date).AddDays(-55)

# Import modules and connect to Microsoft Graph
Import-Module Microsoft.Graph.Beta.DeviceManagement
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All" -NoWelcome

# Get devices from Microsoft Graph, filter by LastSyncDateTime, and add DaysSinceLastSync
Get-MgBetaDeviceManagementManagedDevice |
    Where-Object { $_.LastSyncDateTime -lt $thresholdDate } |
    Select-Object LastSyncDateTime, 
                  @{Name="DaysSinceLastSync"; Expression={(Get-Date) - $_.LastSyncDateTime | Select-Object -ExpandProperty Days}},
                  UserPrincipalName, 
                  DeviceName, 
                  Manufacturer, 
                  Model, 
                  OperatingSystem, 
                  OSVersion, 
                  ComplianceState, 
                  ManagementState, 
                  ManagedDeviceOwnerType, 
                  JoinType, 
                  ManagementCertificateExpirationDate |
    Sort-Object LastSyncDateTime | Out-GridView    