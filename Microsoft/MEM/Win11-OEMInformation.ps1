<#
  .NOTES
  ===========================================================================
   Created on:   	03.12.2021
   Created by:   	Simon Skotheimsvik
   Filename:     	Win11-OEMInformation.ps1
   Info:          https://skotheimsvik.blogspot.com
  ===========================================================================
  
  .DESCRIPTION
    This script sets the support information for Windows10 and Windows 11
    The information is found in Settings - System - About - Support
    The script can be assigned to devices in Microsoft Endpoint Manager.
    
  .EXAMPLE
    Win11-OEMInformation.ps1 
#>

$RegKeyPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation'

$SupportURL = "SupportURL"
$Manufacturer = "Manufacturer"
$SupportHours = "SupportHours"
$SupportPhone = "SupportPhone"

$SupportURLValue = "https://support.cloudlimits.com/"
$ManufacturerValue = "Cloud Limits"  
$SupportHoursValue = "Standard: 0700-1600, Extended: 24-7-365"
$SupportPhoneValue = "+47 12 34 56 78"


IF(!(Test-Path $RegKeyPath))
{
New-Item -Path $RegKeyPath -Force | Out-Null
}

New-ItemProperty -Path $RegKeyPath -Name $SupportURL -Value $SupportURLValue -PropertyType STRING -Force | Out-Null
New-ItemProperty -Path $RegKeyPath -Name $Manufacturer -Value $ManufacturerValue -PropertyType STRING -Force | Out-Null
New-ItemProperty -Path $RegKeyPath -Name $SupportHours -Value $SupportHoursValue -PropertyType STRING -Force | Out-Null
New-ItemProperty -Path $RegKeyPath -Name $SupportPhone -Value $SupportPhoneValue -PropertyType STRING -Force | Out-Null


# Clears the error log from powershell before exiting
    $error.clear()