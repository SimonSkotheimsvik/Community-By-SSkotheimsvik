<#
  .NOTES
  ===========================================================================
   Created on:   	04.06.2024
   Created by:   	Simon Skotheimsvik
   Filename:     	Get-WindowsCorporateIdentifier.ps1
   Info:            https://skotheimsvik.no
  ===========================================================================
  
  .DESCRIPTION
    This script gets a CSV with corporate identifier data from Windows10 and Windows 11
    to be used in Microsoft Intune for Autopilot Device Preparation.
#>

# Capture the output from WMI objects
$computerSystem = Get-WmiObject -Class Win32_ComputerSystem
$bios = Get-WmiObject -Class Win32_BIOS

# Combine the results into a single string
$data = "$($computerSystem.Manufacturer),$($computerSystem.Model),$($bios.SerialNumber)"

# Write the data to a CSV file without headers
Set-Content -Path "system_info.csv" -Value $data