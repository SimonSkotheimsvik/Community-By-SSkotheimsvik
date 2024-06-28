<#
  .NOTES
   Created on:    26.06.2024
   Created by:    Simon Skotheimsvik
   Filename:      StartURLonLogon-Detection.ps1
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
    $ExistingValue = (Get-Item -Path $($Reg.RegKeyPath)).GetValue($($Reg.Key))
    if ($ExistingValue -ne $($Reg.Value)) {
      Write-Host $($Reg.Key) "Not Equal"
      Exit 1      
    }
    else {
#      Write-Host $($Reg.Key) "Equal"
    }
}
Exit 0