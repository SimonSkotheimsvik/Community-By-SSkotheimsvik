<#
.SYNOPSIS
  Script to find devices with LAPS passwords.
.DESCRIPTION
    This script will find all devices with a LAPS password set. Use this to find the prevalence of LAPS in your environment.
    
.NOTES
    Version:        1.1
    Author:         Simon Skotheimsvik
    Info:           https://skotheimsvik.no/migrating-cloud-laps-to-the-new-windows-laps       
    Creation Date:  09.06.2023
    Version history:
    1.0 - (09.06.2023) Script released
    1.1 - (24.10.2023) Least privilege (Thanks  to Sandy Zeng)

#>

#region connect
Connect-MgGraph -Scopes "Device.Read.All", "DeviceLocalCredential.ReadBasic.All"
#region connect

#region variables
$devices = get-mgdevice -Filter "OperatingSystem eq 'Windows'" -All
$NumberOfDevices = $devices.count
$NumberOfDevicesWithLaps = 0
$Counter = 1
#endregion variables

#region find devices with LAPS passwords
foreach ($device in $devices) {
    if (Get-LapsAADPassword -DeviceIds $device.DisplayName -erroraction 'silentlycontinue') {$NumberOfDevicesWithLaps++}
    Write-Progress -Activity "Searching device $Counter : $NumberOfDevices for LAPS" -PercentComplete (($Counter / $NumberOfDevices) * 100)
    $Counter++
}
#endregion 

#region write result
Write-Host "$NumberOfDevicesWithLaps of $NumberOfDevices Windows devices have Windows LAPS password."
#end region
