<#
.SYNOPSIS
    Script to get devices registered with Corporate Device Identifiers.
.DESCRIPTION
    This script retrieves and summarizes information about devices registered with corporate device identifiers in Microsoft Intune.
.EXAMPLE
    
.NOTES
    Author:         Simon Skotheimsvik
    Contact:        skotheimsvik.no
    Version history:
    1.0 - (09.09.2025) Script released, Simon Skotheimsvik

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

# Text for reporting
$summaryText = @"
A summary of devices imported with corporate device identifiers:
Total imported devices: $deviceCount
Enrolled devices: $enrolledCount
Not contacted devices: $notContactedCount
Timespan of imported devices: $(
    if ($createdDates.Count -gt 0) {
        "$($createdDates[0]) to $($createdDates[-1])"
    } else {
        "No devices found"
    }
)
"@

Write-Host "`n$summaryText"