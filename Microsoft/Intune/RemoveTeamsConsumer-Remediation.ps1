<#
  .NOTES
  ===========================================================================
   Created on:   	07.02.2023
   Created by:   	Simon Skotheimsvik
   Filename:     	RemoveTeamsConsumer-Remediation.ps1
   Instructions:    https://www.inthecloud247.com/remove-the-built-in-teams-client-and-chat-icon-from-windows-11/
  ===========================================================================
  
  .DESCRIPTION
    This script will remediate if Teams Consumer is present
    Based on https://www.inthecloud247.com/remove-the-built-in-teams-client-and-chat-icon-from-windows-11/

    Detection script:                                   Yes
    Remediation script:                                 Yes
    Run this script using the logged-on credentials:    Yes
    Enforce script signature check:                     No
    Run script in 64-bit PowerShell:                    Yes
    
#>

try {
    Get-AppxPackage -Allusers -Name MicrosoftTeams | Remove-AppxPackage -ErrorAction stop
    Write-Host "Microsoft Teams app successfully removed"

}
catch {
    Write-Error "Errorremoving Microsoft Teams app"
}