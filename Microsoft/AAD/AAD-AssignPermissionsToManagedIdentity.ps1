<#
    .SYNOPSIS
    Created on:     19.02.2024
    Created by:     CloudWay, Simon Skotheimsvik
    Info:           Entra Role Assignments
    
    .DESCRIPTION
    Routine to add necessary roles to System Assigned Managed Identity in Function App or Automation Account.
#>

# Install-Module Microsoft.Graph -Scope CurrentUser
Import-Module Microsoft.Graph.Applications

# Variables
$TenantID = "YOUR VALUE HERE"
$managedIdentityId = "YOUR VALUE HERE"
$roleNames = "User.Read.All","Calendars.ReadWrite"

# Connect to Graph
Connect-MgGraph -Scopes Application.Read.All, AppRoleAssignment.ReadWrite.All, RoleManagement.ReadWrite.Directory -TenantId $TenantID

# Get the Microsoft Graph Service Principal
$msgraph = Get-MgServicePrincipal -Filter "AppId eq '00000003-0000-0000-c000-000000000000'"

# Set the app role assignments
foreach ($roleName in $roleNames) {
    write-host $roleName
    $role = $Msgraph.AppRoles| Where-Object {$_.Value -eq $roleName} 
    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $managedIdentityId -PrincipalId $managedIdentityId -ResourceId $msgraph.Id -AppRoleId $role.Id
}
 
Disconnect-MgGraph