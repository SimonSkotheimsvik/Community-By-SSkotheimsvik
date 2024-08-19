<#
.SYNOPSIS
    Script to investigate passkeys in use in Entra ID
.DESCRIPTION
    The script will connect to Microsoft Graph and retrieve user registration details for passkey device-bound methods.
    This script will list all the unique AaGuids for FIDO2 methods in use in Entra ID.
    It will then retrieve the unique AaGuids for FIDO2 methods and output them in a table format with details on each user having passkeys.
.PARAMETER None
    This script does not accept any parameters.
    
.NOTES
    Author:         Simon Skotheimsvik
    Info:           https://skotheimsvik.no        
    Creation Date:  2024.08.19
    Version history:
                    1.0 - (2024.08.19) Script released, Simon Skotheimsvik
#>

#region Connect
# Install the Microsoft Graph module
# Install-Module Microsoft.Graph

# Connect to Microsoft Graph with the required scopes
Connect-MgGraph -Scope AuditLog.Read.All,UserAuthenticationMethod.Read.All
#endregion

#region Get Users
# Retrieve and process user registration details for passkey device-bound methods
$users = Get-MgReportAuthenticationMethodUserRegistrationDetail -Filter "methodsRegistered/any(i:i eq 'passKeyDeviceBound')" -All
$userIds = $users.Id
#endregion

#region Unique AaGuids
# Get unique AaGuids for FIDO2 methods
$aaGuids = $userIds | ForEach-Object { Get-MgUserAuthenticationFido2Method -UserId $_ -All } | Select-Object -ExpandProperty AaGuid -Unique

# Output the unique AaGuids
$aaGuids
#endregion

#region User Passkey Details
# Initialize an array to store the results
$result = @()

# Loop through each user and get their FIDO2 methods
foreach ($user in $users) {
    $fidoMethods = Get-MgUserAuthenticationFido2Method -UserId $user.Id -All
    foreach ($method in $fidoMethods) {
        $result += [PSCustomObject]@{
            Username = $user.UserPrincipalName
            DisplayName = $user.DisplayName
            AaGuid = $method.AaGuid
            Model = $method.Model
            DislplayName = $method.DisplayName
            CreatedDateTime = $method.CreatedDateTime
        }
    }
}

# Output the results in a table format
$result | ft
#endregion