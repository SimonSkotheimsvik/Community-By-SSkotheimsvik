<#
.SYNOPSIS
    This script is used to check the health state for user principal names and enrolled-by user principal names for Windows devices in Intune.

.DESCRIPTION
    Connects to Microsoft Graph, queries Windows devices for primary user and enrolled by user.
    Several alternative ways of reporting on the data.

.NOTES
    Author:    Simon Skotheimsvik
    Version:   1.0.0 - 2025.08.11 - Initial version, Simon Skotheimsvik
    Copyright: (c) 2025 Simon Skotheimsvik
    License:   MIT
#>

#region prerequisites
if (Get-Module -ListAvailable -Name Microsoft.Graph.DeviceManagement) {
    Write-Host "Microsoft Graph Device Management Already Installed"
} 
else {
    Install-Module -Name Microsoft.Graph.DeviceManagement -Scope CurrentUser -Repository PSGallery -Force -RequiredVersion 1.19.0 
    Write-Host "Microsoft Graph Device Management Installed"
}
#endregion

#region Connect to Microsoft Graph
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"
}
#endregion

#region Query Devices
# Step 1: Get all Windows devices
$allWindowsDevices = Get-MgDeviceManagementManagedDevice -Filter "operatingSystem eq 'Windows'" -All
# Step 2: Filter locally for Entra ID joined devices (can be heavy in some tenants filtering locally)
$devices = $allWindowsDevices | Where-Object { $_.deviceEnrollmentType -eq 'windowsAzureADJoin' }
#endregion

#region Prepare output array
$deviceReport = @()

$deviceReport = foreach ($device in $devices) {
    $deviceId = $device.Id

    # Query full device object by ID
    # Heavy to run in large environments, but had to be done to get full details
    $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$deviceId')?`$select=deviceName,userPrincipalName,enrolledByUserPrincipalName"
    $details = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject

    # Compare UPNs
    $mismatch = if ($details.userPrincipalName -ne $details.enrolledByUserPrincipalName) { "Yes" } else { "No" }

    # Add to report
    [PSCustomObject]@{
        DeviceName                  = $details.deviceName
        UserPrincipalName           = $details.userPrincipalName
        EnrolledByUserPrincipalName = $details.enrolledByUserPrincipalName
        Mismatch                    = $mismatch
    }
}
#endregion

#region Display results
# Show all devices
$deviceReport | Out-GridView -Title "Device Report"

# Show only mismatched entries
$deviceReport | Where-Object { $_.Mismatch -eq "Yes" } | Out-GridView -Title "Mismatched Devices"

# Show only devices enrolled by john.doe@contoso.com
$deviceReport | Where-Object { $_.EnrolledByUserPrincipalName -eq "john.doe@contoso.com" } | Format-Table -AutoSize

# Show only devices where primary user is john.doe@contoso.com
$deviceReport | Where-Object { $_.UserPrincipalName -eq "john.doe@contoso.com" } | Format-Table -AutoSize

# Show details on named device
$deviceReport | Where-Object { $_.DeviceName -eq "PC-123456789Z" } | Format-Table -AutoSize

# Count number of devices enrolled by each user
$deviceReport |
    Group-Object -Property EnrolledByUserPrincipalName |
    Sort-Object -Property Count -Descending |
    Select-Object Name, Count |
    Out-GridView

# Count number of devices enrolled by each user, include the computernames and show users with multiple devices enrolled
$deviceReport |
    Group-Object -Property EnrolledByUserPrincipalName |
    Where-Object { $_.Count -gt 1 } |
    Sort-Object -Property Count -Descending |
    ForEach-Object {
        [PSCustomObject]@{
            EnrolledByUser = $_.Name
            DeviceCount     = $_.Count
            DeviceNames     = ($_.Group | Select-Object -ExpandProperty DeviceName) -join ", "
        }
    } | Out-GridView -Title "Devices Enrolled by User"

#endregion