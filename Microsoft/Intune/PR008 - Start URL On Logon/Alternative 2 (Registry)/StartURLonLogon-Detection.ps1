<#
  .NOTES
   Created on:    26.06.2024
   Author:        Simon Skotheimsvik
   Filename:      StartURLonLogon-Detection.ps1
   Info:          https://skotheimsvik.no 
   Versions:       
                  1.0.0, 26.06.2024, Initial version
                  1.0.1, 22.09.2025, Updated output                
  
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
      Write-Output "$($Reg.Key) Not Equal. $($ExistingValue) should be $($Reg.Value)"
      Exit 1      
    }
    else {
#      Write-Host $($Reg.Key) "Equal"
    }
}
Write-Output "Registry values are correct."
Exit 0