# Example PowerShell script to list applications with scope permissions.

# First, connect to Microsoft Graph with the necessary permissions
Connect-MgGraph -Scopes "Application.Read.All"

# Define an array of grant scopes
# $GrantScopes = @("mail.read", "calendars.read", "user.read", "user_impersonation")
$GrantScopes = @("ReadWrite", "FullControl", "AccessAsUser", "Write")

# Get all Enterprise Applications
$EnterpriseApps = Get-MgServicePrincipal

# Iterate through each Enterprise Application
foreach ($app in $EnterpriseApps) {
    # Get the OAuth2PermissionGrants for the current Enterprise Application
    $OAuth2PermissionGrants = Get-MgServicePrincipalOAuth2PermissionGrant -ServicePrincipalId $app.Id
    
    # Initialize a hashtable to track grant scopes for this app
    $AppScopes = @{}
    
    # Check each OAuth2PermissionGrant against the defined scopes
    foreach ($grant in $OAuth2PermissionGrants) {
        foreach ($scope in $GrantScopes) {
            if ($grant.Scope -like "*$scope*") {
                $AppScopes[$scope] = $true
            }
        }
    }

    # Output information about the application and its grant scopes
    Write-Host "Application Name: $($app.DisplayName)"
    foreach ($scope in $GrantScopes) {
        if ($AppScopes[$scope]) {
            Write-Host "  - $scope permission is granted." -ForegroundColor red
        } else {
            Write-Host "  - $scope permission is not granted." -ForegroundColor green
        }
    }
}
