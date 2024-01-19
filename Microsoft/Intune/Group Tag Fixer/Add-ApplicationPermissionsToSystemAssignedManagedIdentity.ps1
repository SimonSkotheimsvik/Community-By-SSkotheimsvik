<#
    .SYNOPSIS
    Created on:     01.06.2023
    Modified on:    02.06.2023
    Created by:     CloudWay, Simon Skotheimsvik
    Info:           CloudWay Services, Evergreen Roadmap, Group Tag Fixer
    
    .DESCRIPTION
    Routine to add application persmissions to system assigned managed identity.
#>

#region Variables
$TenantID = "11111111-1111-1111-1111-111111111111"
$ServicePrincipalId = "22222222-2222-2222-2222-222222222222"
#endregion Variables

#region Connect to Microsoft Graph
Connect-MgGraph -TenantId $TenantID -Scopes "Application.Read.All","AppRoleAssignment.ReadWrite.All","RoleManagement.ReadWrite.Directory"
#endregion connect

#region Set Service Principal Permissions
$graphStdApp = Get-MgBetaServicePrincipal -Filter "AppId eq '00000003-0000-0000-c000-000000000000'"
$app_roles = "DeviceManagementServiceConfig.ReadWrite.All", "Device.Read.All"
$Permissions = $graphStdApp.AppRoles | Where-Object {$_.value -in $app_roles}
foreach ($Permission in $Permissions) {
    New-MgBetaServicePrincipalAppRoleAssignment -ServicePrincipalId $ServicePrincipalId -PrincipalId $ServicePrincipalId -AppRoleId $Permission.Id -ResourceId $graphStdApp.Id
}

#endregion set

# Disconnect-MgGraph