<#
  .NOTES
   Created on:    07.10.2024
   Created by:    Simon Skotheimsvik
   Filename:      Autopatch-NoAutoUpdate-Remediation.ps1
   Info:          https://skotheimsvik.no 
   Version:       1.0.5
  
  .DESCRIPTION
    This remediation script checks if the registry key exists and holds a different value than expected. If the value is different, the script will clean up the registry key.
#>

$RegKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$RegKey = "NoAutoUpdate"
$ExpectedValue = 0

try {
    if (Test-Path -Path $RegKeyPath) {
        try {
            $ExistingValue = Get-ItemPropertyValue -Path $RegKeyPath -Name $RegKey -ErrorAction SilentlyContinue
            if ($ExistingValue -eq $null) {
                Write-Host "Registry key does not exist. No remediation needed."
                Exit 0 # No changes required
            } elseif ($ExistingValue -ne $ExpectedValue) {
                # Stop the Windows Update service
                Stop-Service -Name wuauserv -Force

                Set-ItemProperty -Path $RegKeyPath -Name $RegKey -Value $ExpectedValue -ErrorAction SilentlyContinue
                Write-Host "Set key: $RegKey in path $RegKeyPath to the expected value $ExpectedValue."

                # Start the Windows Update service
                Start-Service -Name wuauserv

                Exit 1 # Remediation successful
            } else {
                Write-Host "$($RegKey) in path $($RegKeyPath) equals $($ExistingValue). No remediation needed."
                Exit 0 # No changes required
            }
        } catch {
            Write-Host "$_. No remediation needed."
            Exit 0 # No changes required
        }
    } else {
        Write-Host "Registry path does not exist. No remediation needed."
        Exit 0 # No changes required
    }
} catch {
    Write-Host "Error accessing registry path ${RegKeyPath}: $_"
    Exit 1 # Error occurred
}