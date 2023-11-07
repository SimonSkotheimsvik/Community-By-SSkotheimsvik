<#
  .NOTES
  ===========================================================================
   Created on:   	07.11.2023
   Created by:   	Simon Skotheimsvik
   Filename:     	DisableJavaScriptOnAdobeAcrobat-Remediation.ps1
   Info:          https://skotheimsvik.no
  ===========================================================================
  
  .DESCRIPTION
    The script can be assigned as Remediation script in Microsoft Intune
#>

$RegSettingContent = @"
RegKeyPath,Key,Value,Type
"HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown","bDisableJavaScript","1","DWORD"
"HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown","bDisableJavaScript","1","DWORD"
"@

$RegSetting = $RegSettingContent | ConvertFrom-Csv -delimiter ","

foreach ($Reg in $RegSetting) {

    IF (!(Test-Path ($Reg.RegKeyPath))) {
        Write-Host ($Reg.RegKeyPath) " does not exist. Will be created."
        New-Item -Path $RegKeyPath -Force | Out-Null
    }
    IF (!(Get-Item -Path $($Reg.Key))) {
        Write Host $($Reg.Key) " does not exist. Will be created."
        New-ItemProperty -Path $($Reg.RegKeyPath) -Name $($Reg.Key) -Value $($Reg.Value) -PropertyType $($Reg.Type) -Force
    }
    
    $ExistingValue = (Get-Item -Path $($Reg.RegKeyPath)).GetValue($($Reg.Key))
    if ($ExistingValue -ne $($Reg.Value)) {
        Write-Host $($Reg.Key) " not correct value. Will be set."
        Set-ItemProperty -Path $($Reg.RegKeyPath) -Name $($Reg.Key) -Value $($Reg.Value) -Force
    }
    else {
        Write-Host $($Reg.Key) " is correct"
    }
}

Exit 0