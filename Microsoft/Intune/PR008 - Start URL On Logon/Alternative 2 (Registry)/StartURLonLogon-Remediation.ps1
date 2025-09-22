<#
  .NOTES
   Created on:  26.06.2024
   Author:      Simon Skotheimsvik
   Filename:    StartURLonLogon-Remediation.ps1
   Info:        https://skotheimsvik.no 
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
$RemediationFailed = $false

foreach ($Reg in $RegData) {
    try {
        IF (!(Test-Path ($Reg.RegKeyPath))) {
            Write-Output "$($Reg.RegKeyPath) does not exist. Will be created."
            New-Item -Path $($Reg.RegKeyPath) -Force | Out-Null
        }
        
        IF ((Get-ItemProperty -Path $Reg.RegKeyPath -Name $Reg.Key -ErrorAction SilentlyContinue) -eq $null) {
            Write-Output "$($Reg.Key) does not exist. Will be created."
            New-ItemProperty -Path $($Reg.RegKeyPath) -Name $($Reg.Key) -Value $($Reg.Value) -PropertyType $($Reg.Type) -Force
        }
        
        $ExistingValue = (Get-Item -Path $($Reg.RegKeyPath)).GetValue($($Reg.Key))
        if ($ExistingValue -ne $($Reg.Value)) {
            Write-Output "$($Reg.Key) not correct value. Will be set."
            Set-ItemProperty -Path $($Reg.RegKeyPath) -Name $($Reg.Key) -Value $($Reg.Value) -Force
        }
        else {
            Write-Output "$($Reg.Key) is correct"
        }
    }
    catch {
        Write-Output "Failed to process $($Reg.Key) at $($Reg.RegKeyPath): $_"
        $RemediationFailed = $true
    }
}

if ($RemediationFailed) {
    # At least one of the remediation steps failed
    Exit 1
}
else {
    Exit 0
}
