<#
.SYNOPSIS
  Script to find devices with LAPS passwords.
.DESCRIPTION
    This script will find all devices with a LAPS password set. Use this to find the prevalence of LAPS in your environment.
.EXAMPLE
    
.NOTES
    Version:        1.0
    Author:         Simon Skotheimsvik
    Info:           https://skotheimsvik.no        
    Creation Date:  09.06.2023
    Version history:
    1.0 - (09.06.2023) Script released

#>

#region variables
$devices = get-mgdevice -All
$NumberOfDevices = $devices.count
$NumberOfDevicesWithLaps = 0
$Counter = 1
#endregion variables

#region find devices with LAPS passwords
foreach ($device in $devices) {
    if (Get-LapsAADPassword -DeviceIds $device.Id -erroraction 'silentlycontinue') {$NumberOfDevicesWithLaps++}
    Write-Progress -Activity "Searching device $Counter : $NumberOfDevices for LAPS" -PercentComplete (($Counter / $NumberOfDevices) * 100)
    $Counter++
}
#endregion 

#region write result
Write-Host "$NumberOfDevicesWithLaps of $NumberOfDevices have LAPS enabled."
#end region