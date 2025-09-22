<#
.SYNOPSIS
    This script is used to check the health state for user principal names and enrolled-by user principal names for Windows devices in Intune.

.DESCRIPTION
    Connects to Microsoft Graph, queries Windows devices for primary user and enrolled by user.
    Several alternative ways of reporting on the data.

.NOTES
    Author:    Simon Skotheimsvik
    Versions:   
                1.0.0 - 2025.08.11 - Initial version, Simon Skotheimsvik
                1.0.1 - 2025.08.28 - Better routine for prerequisites, Simon Skotheimsvik
                1.0.2 - 2025.09.03 - Added progress bar, Simon Skotheimsvik
                1.0.3 - 2025.09.09 - Added enrollmentProfileName to the report to find DEM accounts used with Autopilot, Simon Skotheimsvik
    Copyright: (c) 2025 Simon Skotheimsvik
    License:   MIT
#>

#region prerequisites
try {
    Import-Module Microsoft.Graph.DeviceManagement -ErrorAction Stop
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Write-Host "Required modules imported successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to import required modules. Please install Microsoft.Graph.DeviceManagement module." -ForegroundColor Red
    Write-Host "Run: Install-Module Microsoft.Graph.DeviceManagement -Force" -ForegroundColor Yellow
    exit 1
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

    # Progress bar
    $currentIndex = [array]::IndexOf($devices, $device) + 1
    $percentComplete = [int](($currentIndex / $devices.Count) * 100)
    Write-Progress -Activity "Processing devices" -Status "$currentIndex of $($devices.Count)" -PercentComplete $percentComplete

    # Query full device object by ID
    # Heavy to run in large environments, but had to be done to get full details
    $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$deviceId')?`$select=deviceName,userPrincipalName,enrolledByUserPrincipalName,enrollmentProfileName"
    $details = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject

    # Compare UPNs
    $mismatch = if ($details.userPrincipalName -ne $details.enrolledByUserPrincipalName) { "Yes" } else { "No" }

    # Add to report
    [PSCustomObject]@{
        DeviceName                  = $details.deviceName
        UserPrincipalName           = $details.userPrincipalName
        EnrolledByUserPrincipalName = $details.enrolledByUserPrincipalName
        EnrollmentProfileName       = $details.enrollmentProfileName
        Mismatch                    = $mismatch
    }
}
Write-Progress -Activity "Processing devices" -Completed
Write-Host "Number of devices processed: $($deviceReport.Count)" -ForegroundColor Cyan
#endregion

#region Display results
$TotalDevices = $devices.Count
# Show all devices
$deviceReport | Out-GridView -Title "Device Report"

# Show only mismatched entries
$deviceCount = ($deviceReport | Where-Object { $_.Mismatch -eq "Yes" }).Count
$deviceReport | Where-Object { $_.Mismatch -eq "Yes" } | Out-GridView -Title "Mismatch on $($deviceCount) of $($TotalDevices) devices"

# Show only devices enrolled by john.doe@contoso.com
$EnrollmentUser = "EnrollmentManager@johnpaul.ie"
$deviceReport | Where-Object { $_.EnrolledByUserPrincipalName -eq $EnrollmentUser } | Format-Table -AutoSize
$deviceReport | Where-Object { $_.EnrolledByUserPrincipalName -eq $EnrollmentUser } | Measure

# Show only devices where primary user is john.doe@contoso.com
$UserPrincipalName = "EnrollmentManager@johnpaul.ie"
$deviceReport | Where-Object { $_.UserPrincipalName -eq $UserPrincipalName } | Format-Table -AutoSize
$deviceReport | Where-Object { $_.UserPrincipalName -eq $UserPrincipalName } | Measure

# Show details on named device
$deviceReport | Where-Object { $_.DeviceName -eq "PC-123456789Z" } | Format-Table -AutoSize

# Count number of devices enrolled by each user
$deviceReport |
    Group-Object -Property EnrolledByUserPrincipalName |
    Sort-Object -Property Count -Descending |
    Select-Object Name, Count |
    Out-GridView -Title "Device count by EnrolledByUserPrincipalName"

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

# Find all devices enrolled by a specific user, show enrollment profile name to find DEM accounts used with Autopilot
    $EnrollmentUser = "EnrollmentManager@johnpaul.ie"
    $deviceReport | Where-Object { $_.EnrolledByUserPrincipalName -eq $EnrollmentUser } | Select-Object DeviceName, EnrolledByUserPrincipalName, EnrollmentProfileName | Out-GridView -Title "Devices enrolled by $EnrollmentUser with enrollment profile name"

# Count number of devices by EnrollmentProfileName where EnrolledByUserPrincipalName is $EnrollmentUser
    $EnrollmentUser = "EnrollmentManager@johnpaul.ie"
    $deviceReport |
        Where-Object { $_.EnrolledByUserPrincipalName -eq $EnrollmentUser } |
        Group-Object -Property EnrollmentProfileName |
        Sort-Object -Property Count -Descending |
        Select-Object Name, Count |
        Out-GridView -Title "Device count by EnrollmentProfileName for $EnrollmentUser"

#endregion