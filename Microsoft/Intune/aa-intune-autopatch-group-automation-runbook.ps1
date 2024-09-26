<#
.SYNOPSIS
This script separates Windows devices based on their operating system version and adds them to respective Entra ID groups.

.DESCRIPTION
This script retrieves Windows devices from Intune, separates them into Windows 10 and Windows 11 devices based on their OS version, and adds them to the corresponding Entra ID groups.

.NOTES
Author:  Simon Skotheimsvik
Version:
        1.0.0 - 2024-09-23 - Initial release, Simon Skotheimsvik
        1.0.1 - 2024-09-24 - Added the ability to run the script in Azure Automation using managed identity, Simon Skotheimsvik
#>

# Define the Entra ID group names
$windows10GroupName = "Windows 10 Autopatch - Device Registration"
$windows11GroupName = "Windows 11 Autopatch - Device Registration"

# Import the module
$RequiredModules = @('Microsoft.Graph.Authentication', 'Microsoft.Graph.DeviceManagement', 'Microsoft.Graph.Groups', 'Microsoft.Graph.Identity.DirectoryManagement')
foreach ($RequiredModule in $RequiredModules) {
    try {
        Write-Host "Importing $RequiredModule"
        Import-Module $RequiredModule -Force
    }
    catch {
        Write-Error -Exception $_.Exception.Message
    }
}

# Authenticate to Microsoft Graph interactively
# Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All", "GroupMember.ReadWrite.All", "Device.Read.All" -NoWelcome

# Authenticate to Microsoft Graph using managed identity in Runbook
Connect-MgGraph -Identity -NoWelcome

# Get group IDs based on group names
$windows10Group = Get-MgGroup -Filter "DisplayName eq '$windows10GroupName'"
$windows11Group = Get-MgGroup -Filter "DisplayName eq '$windows11GroupName'"

$windows10GroupId = $windows10Group.Id
$windows11GroupId = $windows11Group.Id

# Initialize arrays
$windows10Devices = @()
$windows11Devices = @()

# Get all Windows devices from Intune
$devices = Get-MgDeviceManagementManagedDevice | Where-Object { $_.OperatingSystem -like "Windows*" }

# Separate devices based on OS version
foreach ($device in $devices) {
    if ($device.OSVersion -lt "10.0.22000") {
        $windows10Devices += $device
    }
    elseif ($device.OSVersion -ge "10.0.22000") {
        $windows11Devices += $device
    }
}

# Retrieve all current group members
$windows10GroupMembers = @()
$windows11GroupMembers = @()
$windows10GroupMembers = Get-MgGroupMember -GroupId $windows10GroupId -All | Select-Object -ExpandProperty Id
$windows11GroupMembers = Get-MgGroupMember -GroupId $windows11GroupId -All | Select-Object -ExpandProperty Id

# Add devices to respective Entra ID groups

# Add Windows 11 devices to the Windows 11 group
foreach ($device in $windows11Devices) {
    $deviceId = (Get-MgDevice -Filter "DeviceID eq '$($device.AzureAdDeviceId)'").id
    if ($windows11GroupMembers -notcontains $deviceId) {
        try {
            New-MgGroupMember -GroupId $windows11GroupId -DirectoryObjectId $deviceId
            Write-Warning "Added $($device.DeviceName) to Windows 11 group."
        }
        catch {
            Write-Error "Failed to add $($device.DeviceName) to Windows 11 group: $_"
        }
    }
    else {
        Write-Output "$($device.DeviceName) is already a member of the Windows 11 group."
    }
}

# Loop through Windows 10 devices and check if it is not part of the Win10 or Win11 group, then add them to the Windows 10 group
# If the device is part of the Windows 11 group, remove it from the Windows 10 group. 
# This can happen if devices are moved manually between groups in Entra ID to do autopatching.
foreach ($device in $windows10Devices) {
    $deviceId = (Get-MgDevice -Filter "DeviceID eq '$($device.AzureAdDeviceId)'").id
    if ($windows10GroupMembers -notcontains $deviceId -and $windows11GroupMembers -notcontains $deviceId) {
        try {
            New-MgGroupMember -GroupId $windows10GroupId -DirectoryObjectId $deviceId
            Write-Warning "Added $($device.DeviceName) to Windows 10 group."
        }
        catch {
            Write-Error "Failed to add $($device.DeviceName) to Windows 10 group: $_"
        }
    }
    elseif ($windows11GroupMembers -contains $deviceId -and $windows10GroupMembers -contains $deviceId) {
        try {
            write-host $deviceId
            Remove-MgGroupMemberByRef -GroupId $windows10GroupId -DirectoryObjectId $deviceId
            Write-Warning "Removed $($device.DeviceName) from Windows 10 group as it is a member of the Windows 11 group."
        }
        catch {
            Write-Error "Failed to remove $($device.DeviceName) from Windows 10 group: $_"
        }
    }
    else {
        Write-Output "$($device.DeviceName) is already a member of the Windows 10 or Windows 11 group."
    }
}