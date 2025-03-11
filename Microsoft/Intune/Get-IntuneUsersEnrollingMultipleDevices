<#
.SYNOPSIS
This scripts list users enrolling many devices in Intune.

.DESCRIPTION
There is a discussion going on using DEM account with Autopilot. This script will list all users enrolling many devices in Intune.
Read this post for a summery: https://call4cloud.nl/using-a-dem-account-windows-autopilot-is-a-bad-idea/

.NOTES
Author:  Simon Skotheimsvik
Version:
        1.0.0 - 2025-02-25 - Initial release, Simon Skotheimsvik
#>


# Connect to Microsoft Graph
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"

# Get all managed devices
$devices = Get-MgDeviceManagementManagedDevice -All

# Process devices and create custom objects
$deviceData = $devices | ForEach-Object {
    $enrollmentUser = $_.ManagedDeviceName -split '_' | Select-Object -First 1
    [PSCustomObject]@{
        EnrollmentUser = $enrollmentUser
        DeviceName = $_.DeviceName
        ManagedDeviceName = $_.ManagedDeviceName
        UserPrincipalName = $_.UserPrincipalName
        OperatingSystem = $_.OperatingSystem
        OSVersion = $_.OSVersion
        Model = $_.Model
        Manufacturer = $_.Manufacturer
        SerialNumber = $_.SerialNumber
        LastSyncDateTime = $_.LastSyncDateTime
    }
}

# Group by enrollment user and filter for those with more than 5 devices
$enrollmentUsersWithDevices = $deviceData | Group-Object EnrollmentUser | 
    Where-Object { $_.Count -gt 5 } | 
    ForEach-Object {
        $_.Group | Add-Member -MemberType NoteProperty -Name DeviceCount -Value $_.Count -PassThru
    } | 
    Sort-Object EnrollmentUser, LastSyncDateTime -Descending

# Display results in GridView
$enrollmentUsersWithDevices | Out-GridView -Title "Enrollment Users with More Than 5 Devices and Device Details"

# Disconnect from Microsoft Graph
Disconnect-MgGraph