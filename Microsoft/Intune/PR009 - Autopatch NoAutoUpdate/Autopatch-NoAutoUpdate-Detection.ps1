<#
  .NOTES
   Created on:    07.10.2024
   Created by:    Simon Skotheimsvik
   Filename:      Autopatch-NoAutoUpdate-Detection.ps1
   Info:          https://skotheimsvik.no 
   Version:       1.0.0
  
  .DESCRIPTION
    This detection script checks if the registry key exists and holds a different value than expected.
#>

$RegContent = @"
RegKeyPath,Key,Value,Type
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU","NoAutoUpdate","0","Dword"
"@

$RegData = $RegContent | ConvertFrom-Csv -delimiter ","

foreach ($Reg in $RegData) {
    # Suppress errors for non-existent registry paths using -ErrorAction SilentlyContinue
    $Item = Get-Item -Path $($Reg.RegKeyPath) -ErrorAction SilentlyContinue
    if ($Item) {
        try {
            # Try to get the value for the specified key
            $ExistingValue = $Item.GetValue($($Reg.Key), $null) # Returns $null if the key does not exist
            if ($ExistingValue -ne $null) {
                # Check if the existing value matches the expected value
                if ($ExistingValue -ne $($Reg.Value)) {
                    Write-Host $($Reg.Key) "Not Equal"
                     Exit 1
                }
                else {
                    # Write-Host $($Reg.Key) "Equal"
                }
            }
        }
        catch {
            # Do nothing if GetValue encounters an error
        }
    }
}
 Exit 0