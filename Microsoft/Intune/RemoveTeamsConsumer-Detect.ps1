<#
  .NOTES
  ===========================================================================
   Created on:   	07.02.2023
   Created by:   	Simon Skotheimsvik
   Filename:     	RemoveTeamsConsumer-Detect.ps1
   Instructions:    https://www.inthecloud247.com/remove-the-built-in-teams-client-and-chat-icon-from-windows-11/
  ===========================================================================
  
  .DESCRIPTION
    This script will detect if Teams Consumer is present
    Based on https://www.inthecloud247.com/remove-the-built-in-teams-client-and-chat-icon-from-windows-11/

    Detection script:                                   Yes
    Remediation script:                                 Yes
    Run this script using the logged-on credentials:    Yes
    Enforce script signature check:                     No
    Run script in 64-bit PowerShell:                    Yes
    
#>

if ($null -eq (Get-AppxPackage -Allusers -Name MicrosoftTeams)) {
    Write-Host "Microsoft Teams client not found"
    exit 0
}
Else {
    Write-Host "Microsoft Teams client found"
    Exit 1

}