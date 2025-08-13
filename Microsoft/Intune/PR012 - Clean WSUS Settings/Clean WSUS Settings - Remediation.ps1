<#
.SYNOPSIS
    Remediation to clean WSUS settings

.DESCRIPTION
    This script removes the WSUS registry settings if they exist.

.NOTES
    Author: Simon Skotheimsvik
    Version: 1.0.0 - 2025-08-12, Simon Skotheimsvik, Initial version

    license: This script is provided as-is, without warranty of any kind. Use at your own risk.
    You may modify and redistribute this script as long as you retain this notice in the code.
#>

$datetime = Get-Date -Format "yyyy-MM-dd HH:mm"

# Stop the Windows Update service
Stop-Service -Name wuauserv -Force

# Remove the registry key
Remove-Item -Path  'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate' -Recurse

# Start the Windows Update service
Start-Service -Name wuauserv

if(test-path -Path 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'){
    #registry item still exists
    Write-Error "Reg item still exists. Remediation failed at $($datetime)"
    Exit 1
} else {
    #registry item doesn't exists
    Write-Output "Remediation succeeded at $($datetime)"
    Exit 0
}