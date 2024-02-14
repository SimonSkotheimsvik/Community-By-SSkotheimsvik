<#
  .NOTES
  ===========================================================================
   Created on:   	14.02.2024
   Created by:   	Simon Skotheimsvik
   Filename:     	BlockAADReg-Remediation
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

    IF (!(Test-Path ($Reg.RegKeyPath))) {
        Write-Host ($Reg.RegKeyPath) " does not exist. Will be created."
        New-Item -Path $($Reg.RegKeyPath) -Force | Out-Null
    }
    
    IF ((Get-ItemProperty -Path $Reg.RegKeyPath -Name $Reg.Key -ErrorAction SilentlyContinue) -eq $null) {
        Write-Host "$($Reg.Key) does not exist. Will be created."
        New-ItemProperty -Path $($Reg.RegKeyPath) -Name $($Reg.Key) -Value $($Reg.Value) -PropertyType Dword -Force
    }
    
    $ExistingValue = (Get-Item -Path $($Reg.RegKeyPath)).GetValue($($Reg.Key))
    if ($ExistingValue -ne $($Reg.Value)) {
        Write-Host "$($Reg.Key) not correct value. Will be set."
        Set-ItemProperty -Path $($Reg.RegKeyPath) -Name $($Reg.Key) -Value $($Reg.Value) -Force
    }
    else {
        Write-Host "$($Reg.Key) is correct"
    }
}

Exit 0
