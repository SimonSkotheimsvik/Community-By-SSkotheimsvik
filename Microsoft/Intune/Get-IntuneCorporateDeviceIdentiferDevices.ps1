<#
.SYNOPSIS
    Script to get devices registered with Corporate Device Identifiers.
.DESCRIPTION
    This script retrieves and summarizes information about devices registered with corporate device identifiers in Microsoft Intune.
    There is also a section to compare these devices with Autopilot registered devices to find potential conflicts.
.EXAMPLE
    
.NOTES
    Author:         Simon Skotheimsvik
    Contact:        skotheimsvik.no
    Version history:
    1.0.0 - (09.09.2025) Script released, Simon Skotheimsvik
    1.0.1 - (10.09.2025) Added section to compare with Autopilot devices, Simon Skotheimsvik

#>


# Install required module if not present
if (-not (Get-Module Microsoft.Graph.Beta.DeviceManagement.Enrollment -ListAvailable)) {
    Install-Module Microsoft.Graph.Beta.DeviceManagement.Enrollment -Force
}

Import-Module-Module Microsoft.Graph.Beta.DeviceManagement.Enrollment


# Connect to Microsoft Graph Beta if not already connected
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "DeviceManagementServiceConfig.Read.All"
}

#region Query Corporate Device Identifiers
# Get all imported device identities (Autopilot devices) from Beta endpoint
$importedDevices = Get-MgBetaDeviceManagementImportedDeviceIdentity -All

# Output relevant identifiers (e.g., Id, SerialNumber, ProductKey, HardwareIdentifier)
$importedDevices | Select-Object ImportedDeviceIdentifier, CreatedDateTime, LastContactedDateTime, EnrollmentState

$deviceCount = $importedDevices.Count
$enrolledCount = ($importedDevices | Where-Object { $_.EnrollmentState -eq "enrolled" }).Count
$notContactedCount = ($importedDevices | Where-Object { $_.EnrollmentState -eq "notContacted" }).Count

Write-Host "Total imported devices: $deviceCount"
Write-Host "Enrolled devices: $enrolledCount"
Write-Host "Not contacted devices: $notContactedCount"

$createdDates = $importedDevices | Select-Object -ExpandProperty CreatedDateTime | Sort-Object
if ($createdDates.Count -gt 0) {
    Write-Host "First CreatedDateTime: $($createdDates[0])"
    Write-Host "Last CreatedDateTime: $($createdDates[-1])"
} else {
    Write-Host "No devices found."
}
#endregion Query Corporate Device Identifiers


#region Find devices also registered as Autopilot devices
# Get all Autopilot devices
$autopilotDevices = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -All

# Create a lookup table for Autopilot serial numbers
$autopilotSerials = $autopilotDevices | Select-Object -ExpandProperty SerialNumber

# Check which imported devices are also registered as Autopilot devices, and get GroupTag if available
$CompareAutopilotAndCorporateDeviceIdentifier = $importedDevices | ForEach-Object {
    $parts = $_.ImportedDeviceIdentifier -split ','
    $serial = $parts[2]
    $isAutopilot = $autopilotSerials -contains $serial

    # Try to find matching Autopilot device for GroupTag
    $autopilotDevice = $autopilotDevices | Where-Object { $_.SerialNumber -eq $serial } | Select-Object -First 1

    [PSCustomObject]@{
        DevicePrepImportedDeviceIdentifier = $_.ImportedDeviceIdentifier
        DevicePrepSerialNumber             = $serial
        DevicePrepCreatedDateTime          = $_.CreatedDateTime
        DevicePrepEnrollmentState          = $_.EnrollmentState
        IsAutopilotDevice        = $isAutopilot
        GroupTag                 = $autopilotDevice.GroupTag
        LastContactedDateTime    = $autopilotDevice.LastContactedDateTime
        Manufacturer             = $autopilotDevice.Manufacturer
        Model                    = $autopilotDevice.Model
    }
}


$CompareAutopilotAndCorporateDeviceIdentifier| Where-Object { $_.IsAutopilotDevice -eq $true } | Out-GridView -Title "Corporate Device Identifiers also registered as Autopilot devices"
#endregion Find devices also registered as Autopilot devices