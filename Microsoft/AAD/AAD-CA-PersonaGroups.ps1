<#
.SYNOPSIS
  Script to create Entra ID CA Persona groups.
.DESCRIPTION
    Script to create role-assignable Entra ID CA Persona groups used for assigning users to Personas targeting Conditional Access policies.
.EXAMPLE
    
.NOTES
    Author:         Simon Skotheimsvik
    Info:           https://skotheimsvik.no        
    Versions:
                1.0.0 - (23.05.2023) Script released
                1.0.1 - (12.03.2024) Convert to Microsoft Graph PowerShell SDK V2 module, Simon Skotheimsvik
                1.0.2 - (10.09.2024) Added new CA Persona for Service Accounts, Simon Skotheimsvik
                1.0.3 - (10.09.2024) Bugfix in finding existing groups, Simon Skotheimsvik
#>

#region Variables
# Insert groups to be created. Security defined after ";"
$GroupNames = @(
    "AZ-Persona-CA-BreakGlassAccounts;secure"
    "AZ-Persona-CA-Admins;secure"
    "AZ-Persona-CA-AzureServiceAccounts;secure"
    "AZ-Persona-CA-Exclude-Block LegacyAuth;secure"
    "AZ-Persona-CA-Global-BaseProtection-Exclusions;secure"
    "AZ-Persona-CA-Internals;normal"
)
$Date = Get-Date -Format "yyyy.MM.dd"
#endregion Variables

#region connect
Connect-MgGraph -Scopes "Directory.Read.All", "Group.ReadWrite.All", "RoleManagement.ReadWrite.Directory"
#Install-Module Microsoft.Graph.Beta.Groups
Import-Module Microsoft.Graph.Beta.Groups
#endregion connect

#region script 
# Create groups in Tenant if not existing
foreach ($Group in $GroupNames) {
    # Create description
    $GroupName = $Group.Split(";")[0]
    $GroupSecurity = $Group.Split(";")[1]
        if ($GroupSecurity -like "secure") { $IsAssignableToRole = $true }
        else { $IsAssignableToRole = $false }

    $GroupDescription = $GroupName.Split("-")[-1]
    $GroupType = $GroupName.Split("-")[1]
        if ($GroupType -like "Persona") {
            $Description = "This group is used to assign user account to the CA Persona: $GroupDescription - $Date, CloudWay."
        }
        elseif ($GroupType -like "APP") {
            $Description = "This group is used to assign user account to CA APP Deviation for the app $GroupDescription - $Date, CloudWay."
        }
    $MailNickName = $grouptype + "." + (($GroupDescription).Replace(" ", "")).Replace("(Hybrid)", "Hybrid")

    # Find group, create it if not existing

    if ($ExistingGroup = Get-MgBetaGroup -Filter "DisplayName eq '$($GroupName)'") {
        Write-Output """$GroupName"" exists"
    }
    else {
        Write-Output """$GroupName"" does not exist. Will be created now as $GroupSecurity."
        $NewGroup = New-MgBetaGroup -DisplayName $GroupName -Description $Description -MailEnabled:$false -MailNickName $MailNickName -SecurityEnabled -IsAssignableToRole:$IsAssignableToRole
    }
}
#endregion script 