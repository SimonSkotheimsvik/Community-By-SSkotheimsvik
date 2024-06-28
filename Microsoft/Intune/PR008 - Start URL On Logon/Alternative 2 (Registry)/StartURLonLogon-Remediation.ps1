<#
  .NOTES
   Created on:    26.06.2024
   Created by:    Simon Skotheimsvik
   Filename:      StartURLonLogon-Remediation.ps1
   Info:          https://skotheimsvik.no 
   Version:       1.0
  
  .DESCRIPTION
    This remediation package adds URL to start on logon.
#>

$RegContent = @"
RegKeyPath,Key,Value,Type
"HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run","SimonDoes","explorer https://skotheimsvik.no","String"
"@

$RegData = $RegContent | ConvertFrom-Csv -delimiter ","

foreach ($Reg in $RegData) {

    IF (!(Test-Path ($Reg.RegKeyPath))) {
        Write-Host ($Reg.RegKeyPath) " does not exist. Will be created."
        New-Item -Path $($Reg.RegKeyPath) -Force | Out-Null
    }
    
    IF ((Get-ItemProperty -Path $Reg.RegKeyPath -Name $Reg.Key -ErrorAction SilentlyContinue) -eq $null) {
        Write-Host "$($Reg.Key) does not exist. Will be created."
        New-ItemProperty -Path $($Reg.RegKeyPath) -Name $($Reg.Key) -Value $($Reg.Value) -PropertyType $($Reg.Type) -Force
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
