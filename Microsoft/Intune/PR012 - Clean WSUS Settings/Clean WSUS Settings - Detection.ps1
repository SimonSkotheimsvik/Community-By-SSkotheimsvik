<#
.SYNOPSIS
    Remediation to clean WSUS settings

.DESCRIPTION
    This script detects the WSUS registry settings.

.NOTES
    Author: Simon Skotheimsvik
    Version: 1.0.0 - 2025-08-12, Simon Skotheimsvik, Initial version

    license: This script is provided as-is, without warranty of any kind. Use at your own risk.
    You may modify and redistribute this script as long as you retain this notice in the code.
#>

$datetime = Get-Date -Format "yyyy-MM-dd HH:mm"

if(test-path -Path 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'){
    #registry item exists
    Write-Output "Reg item exists. Remediation required, $($datetime)"
    Exit 1
} else {
    #registry item doesn't exists
    Write-Output "Reg item doesn't exist. No remediation required, $($datetime)"
    Exit 0
}