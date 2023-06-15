<#
.SYNOPSIS
  Script to register Azure Enterprise Applications.
.DESCRIPTION
    Script to register Azure Enterprise Applications for use in Azure Conditional Access policies.
.EXAMPLE
    
.NOTES
    Version:        1.0
    Author:         CloudWay, Simon Skotheimsvik
    Info:           https://cloudway.com        
    Creation Date: 23.05.2023
    Version history:
    1.0 - (23.05.2023) Script released
#>

#region Variables
# Insert APP IDs for Enterprise Applications to be registered
$APPIDs = @(
    "9cdead84-a844-4324-93f2-b2e6bb768d07"  # Azure Virtual Desktop
    "0af06dc6-e4b5-4f28-818e-e78e62d137a5"  # Cloud PC
    "d4ebce55-015a-49b5-a083-c84d1797ae8c"  # Microsoft Intune Enrollment
)
#endregion Variables

#region connect
Select-MgProfile beta
Connect-MgGraph -Scopes "Application.ReadWrite.All" -ForceRefresh
Import-Module Microsoft.Graph.Applications
#endregion connect

#region script 
# Register Enterprise applications
foreach ($ID in $APPIDs) {
    # Finds Enterprise Applications, register it if not existing
    if ($ExistingApp = Get-MgServicePrincipal -all | Where-Object { $_.AppId -like $ID }) {
        $DisplayName = $ExistingApp.DisplayName
        Write-Output "App with ID ""$ID"" exists as $DisplayName."
    }
    else {
        Write-Output "App with ID ""$ID"" does not exist. Will be created now."
        $ServicePrincipalID = @{
            "AppId" = "$ID"
        }
        New-MgServicePrincipal -BodyParameter $ServicePrincipalId | Format-List id, DisplayName, AppId, SignInAudience
    }
}
#endregion script 