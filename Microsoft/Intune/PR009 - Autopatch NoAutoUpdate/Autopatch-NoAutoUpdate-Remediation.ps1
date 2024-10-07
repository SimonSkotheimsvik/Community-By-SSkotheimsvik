<#
  .NOTES
   Created on:    07.10.2024
   Created by:    Simon Skotheimsvik
   Filename:      Autopatch-NoAutoUpdate-Remediation.ps1
   Info:          https://skotheimsvik.no 
   Version:       1.0.0
  
  .DESCRIPTION
    This remediation package deletes a registry key if it exists and holds a different value than expected.
#>

$RegContent = @"
RegKeyPath,Key,Value,Type
"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU","NoAutoUpdate","0","Dword"
"@

$RegData = $RegContent | ConvertFrom-Csv -delimiter ","

$RemediationRequired = $false
$ErrorOccurred = $false

foreach ($Reg in $RegData) {
    # Use Get-Item to check if the registry path exists without echoing errors
    $Item = Get-Item -Path $($Reg.RegKeyPath) -ErrorAction SilentlyContinue
    if ($Item) {
        try {
            # Attempt to retrieve the existing value, and if not found, return $null
            $ExistingValue = $Item.GetValue($($Reg.Key), $null)
            
            # If the key exists and the value does not match the expected value, delete it
            if ($ExistingValue -ne $null -and $ExistingValue -ne $($Reg.Value)) {
                # Use Remove-ItemProperty to delete the mismatched key
                Remove-ItemProperty -Path $($Reg.RegKeyPath) -Name $($Reg.Key) -ErrorAction SilentlyContinue
                Write-Host "Deleted mismatched key: $($Reg.Key) in path $($Reg.RegKeyPath)"
                $RemediationRequired = $true
            }
        }
        catch {
            # If any errors occur (e.g., permissions), handle them gracefully
            Write-Host "Error accessing key $($Reg.Key) in path $($Reg.RegKeyPath): $_"
            $ErrorOccurred = $true
        }
    }
}

# Exit with appropriate codes based on what happened
if ($ErrorOccurred) {
    Write-Host "Script completed with errors."
    Exit 2 # Exit code 2 indicates an error occurred
}
elseif ($RemediationRequired) {
    Write-Host "Remediation successful."
    Exit 1 # Exit code 1 indicates remediation was needed and successfully applied
}
else {
    Write-Host "No remediation needed."
    Exit 0 # Exit code 0 indicates no changes were required
}