<#
.SYNOPSIS
  Script to create Azure CA Persona groups.
.DESCRIPTION
    Script to create Azure CA Persona groups used for assigning users to Personas targeting Conditional Access policies.
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
# Insert groups to be created
$GroupNames = @(
    "AZ-Persona-CA-BreakGlassAccounts"
    "AZ-Persona-CA0000-Global BaseProtection Exclusions"
    "AZ-Persona-CA0100-Admin Users"
    "AZ-Persona-CA0200-Standard Users"
    "AZ-Persona-CA0300-Front Line Users"
    "AZ-Persona-CA0400-Shared Users"
    "AZ-Persona-CA0500-Service Accounts"
    "AZ-APP-CA-Deviation-Salesforce"
    "AZ-APP-CA-Deviation-idPowerToys"
)
$Date = Get-Date -Format "yyyy.MM.dd"
#endregion Variables

#region connect
Select-MgProfile beta
Connect-MgGraph -Scopes "Directory.Read.All", "Group.ReadWrite.All", "RoleManagement.ReadWrite.Directory" -ForceRefresh
Import-Module Microsoft.Graph.Groups
#endregion connect

#region script 
# Create groups in Tenant if not existing
foreach ($Group in $GroupNames) {
    # Create description
    $GroupDescription = $Group.Split("-")[-1]
    $GroupType = $Group.Split("-")[1]
    if ($GroupType -like "Persona") {
        $Description = "This group is used to assign user account to the CA Persona: $GroupDescription - $Date, CloudWay."
    }
    elseif ($GroupType -like "APP") {
        $Description = "This group is used to assign user account to CA APP Deviation for the app $GroupDescription - $Date, CloudWay."
    }
    $MailNickName = $grouptype+"."+($GroupDescription).Replace(" ", "")

    # Finds group, create it if not existing
    if ($ExistingGroup = Get-MgGroup | Where-Object { $_.DisplayName -like $Group }) {
        Write-Output """$Group"" exists"
    }
    else {
        Write-Output """$Group"" does not exist. Will be created now."
        $NewGroup = New-MgGroup -DisplayName $Group -Description $Description -MailEnabled:$false -SecurityEnabled -MailNickName $MailNickName -IsAssignableToRole # $true -SecurityEnabled $true -Visibility "Hidden"
    }
}
#endregion script 