<#
.SYNOPSIS
  Script to register missing Azure Enterprise Applications.
.DESCRIPTION
    Script to register missing Azure Enterprise Applications for use in CA policies.
.EXAMPLE
    
.NOTES
    Version:        1.2
    Author:         CloudWay, Simon Skotheimsvik
    Info:           https://cloudway.com        
    Creation Date: 23.05.2023
    Version history:
    1.0.0 - (23.05.2023) Script released
    1.1.0 - (29.06.2023) Script updated with Universal Store Service APIs and Web Application
    1.2.0 - (12.02.2024) Convert to Microsoft Graph PowerShell SDK V2 module, Simon Skotheimsvik
    1.2.1 - (11.08.2025) Added the My Staff application ID, Simon Skotheimsvik
    1.2.2 - (10.09.2025) Added Azure Credential Configuration Endpoint Service application ID, Simon Skotheimsvik
    1.2.3 - (24.10.2025) Added Resco MobileCRM application ID, Simon Skotheimsvik
#>

#region Variables
# Insert APP IDs for Enterprise Applications to be registered
$APPIDs = @(
    "9cdead84-a844-4324-93f2-b2e6bb768d07"  # Azure Virtual Desktop
    "0af06dc6-e4b5-4f28-818e-e78e62d137a5"  # Windows 365
    "d4ebce55-015a-49b5-a083-c84d1797ae8c"  # Microsoft Intune Enrollment
    "45a330b1-b1ec-4cc1-9161-9f03992aa49f"  # Windows Store for Business
    "a4a365df-50f1-4397-bc59-1a1564b8bb9c"  # Microsoft Remote Desktop
    "ba9ff945-a723-4ab5-a977-bd8c9044fe61"  # My Staff
    "ea890292-c8c8-4433-b5ea-b09d0668e1a6"  # Azure Credential Configuration Endpoint Service. Source: https://nathanmcnulty.com/blog/2025/09/improving-passkey-registration-experiences/
    "a116bf70-75fe-41c2-9f9f-7f3d0faff4bb"  # Resco MobileCRM
)
#endregion Variables

#region connect
# disconnect-mggraph
Connect-MgGraph -Scopes "Application.ReadWrite.All"
Import-Module Microsoft.Graph.Beta.Applications
#endregion connect

#region script 
# Register Enterprise applications
foreach ($ID in $APPIDs) {
    # Finds Enterprise Applications, register it if not existing
    if ($ExistingApp = Get-MgBetaServicePrincipal -all | Where-Object { $_.AppId -like $ID }) {
        $DisplayName = $ExistingApp.DisplayName
        Write-Output "App with ID ""$ID"" exists as $DisplayName."
    }
    else {
        Write-Output "App with ID ""$ID"" does not exist. Will be created now."
        $ServicePrincipalID = @{
            "AppId" = "$ID"
        }
        New-MgBetaServicePrincipal -BodyParameter $ServicePrincipalId | Format-List id, DisplayName, AppId, SignInAudience
    }
}
#endregion script


#Investigate sign-in logs for a specific app
$events = Get-MgBetaAuditLogSignIn -Filter "conditionalAccessAudiences/any(i:i eq 'ea890292-c8c8-4433-b5ea-b09d0668e1a6')" -All
$events | Select-Object appId,appDisplayName,clientAppUsed,resourceDisplayName,resourceId,servicePrincipalId | Group-Object AppDisplayName | Format-List