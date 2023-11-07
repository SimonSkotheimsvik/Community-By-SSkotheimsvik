<#
  .NOTES
  ===========================================================================
   Created on:   	07.11.2023
   Created by:   	Simon Skotheimsvik
   Filename:     	DisableJavaScriptOnAdobeAcrobat-Detection.ps1
   Info:          https://skotheimsvik.no
  ===========================================================================
  
  .DESCRIPTION
    The script can be assigned as Detection script in Microsoft Intune
#>

$RegSettingContent = @"
RegKeyPath,Key,Value,Type
"HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown","bDisableJavaScript","1","DWORD"
"HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown","bDisableJavaScript","1","DWORD"
"@

$RegSetting = $RegSettingContent | ConvertFrom-Csv -delimiter ","

foreach ($Reg in $RegSetting) {
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