<#
  .NOTES
  ===========================================================================
   Created on:   	14.02.2024
   Created by:   	Simon Skotheimsvik
   Filename:     	BlockAADReg-Detection.ps1
   Info:          https://msendpointmgr.com/2021/03/11/are-you-tired-of-allow-my-organization-to-manage-my-device/
  ===========================================================================
  
  .DESCRIPTION
    This script block users from adding additional work accounts (Entra ID registered) on corporate Windows devices
    
#>

$RegContent = @"
RegKeyPath,Key,Value
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin","BlockAADWorkplaceJoin","1"
"@

$RegData = $RegContent | ConvertFrom-Csv -delimiter ","

foreach ($Reg in $RegData) {
    $ExistingValue = (Get-Item -Path $($Reg.RegKeyPath)).GetValue($($Reg.Key))
    if ($ExistingValue -ne $($Reg.Value)) {
      Write-Host $($Reg.Key) "Not Equal"
      Exit 1
      Exit #Remediation 
    }
    else {
#      Write-Host $($Reg.Key) "Equal"
    }
}
Exit 0