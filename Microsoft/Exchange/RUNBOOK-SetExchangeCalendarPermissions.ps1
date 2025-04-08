<#
    .SYNOPSIS
    Name: RUNBOOK-SetExchangeCalendarPermissions.ps1
    Author: Alexander Holmeset, https://alexholmeset.blog, https://x.com/AlexHolmeset
    Contributor: Simon Skotheimsvik, http://skotheimsvik.no, https://x.com/SSkotheimsvik
    Versions:   1.0 - 2017.10.30 - Simon Skotheimsvik, initial version using ExchangeOnline module
                1.1 - 2024.06.12 - Alexander Holmeset, updated to use Microsoft Graph PowerShell SDK
                1.2 - 2025.04.08 - Simon Skotheimsvik, Bugfix for users with more than 10 defined calender permissions

    .DESCRIPTION
    This script sets the default calendar permissions for all users in a Microsoft 365 organization to LimitedRead.
#>

.DESCRIPTION
This script sets the default calendar permissions for all users in a Microsoft 365 organization to LimitedRead.
#>

# Set the permission level to be set on the calendars.
# Options can be found here: https://learn.microsoft.com/en-us/graph/api/resources/calendarpermission?view=graph-rest-1.0#calendarroletype-values
$Permission = "limitedRead"

# Connects to Microsoft Graph with the specified scopes  
Connect-MgGraph -Identity

# Generates a list of all licensed users in the Microsoft 365 organization with a mailbox
$users = Get-MgUser -All -Property "id", "AssignedLicenses", "UserPrincipalName", "Mail" | Where-Object { $_.AssignedLicenses.Count -gt 0 -and $_.Mail -ne $null}
#$users = Get-MgUser -All -Property "id", "AssignedLicenses", "UserPrincipalName", "Mail" | Where-Object { $_.AssignedLicenses.Count -gt 0 -and $_.Mail -ne $null -and $_.UserPrincipalName -eq "per.skeid@elinett.no"}

# Sets default access to LimitedRead for all calendars in each user's mailbox  
foreach ($user in $users) {   

# Prints the user currently in focus
Write-Output "User in focus = $($user.userprincipalname)"   

# Initializes the variables to store calendar permissions  
$CalenderPermissions = @()  
$CalenderPermissions = Get-MgUserCalendarPermission -All -UserId $user.id 

# If the user has any calendar permissions, update them  
if ($CalenderPermissions) {  
    $CalenderPermissionsMyOrg = @()  
    $CalenderPermissionsMyOrg = $CalenderPermissions | Where-Object { $_.EmailAddress.Name -eq "My Organization" } 
    # Information about the number of calendar permissions for the user 
    Write-Output "- Calendar permissions: $($CalenderPermissions.count)"
    Write-Output "- Calendar permissions MyOrg: $($CalenderPermissionsMyOrg.count)"        

    # Updates the calendar permissions for the user  
    if ($CalenderPermissionsMyOrg.Role -ne $Permission) {
        Write-Warning "- Changing MyOrg-permission on calendar for $($user.userprincipalname) from $($CalenderPermissionsMyOrg.Role) to $($Permission)."   
        Update-MgUserCalendarPermission -UserId $user.id -Role $Permission -CalendarPermissionId $CalenderPermissionsMyOrg.id
    }  
    # If the permission is already set, print a message
    else {  
        Write-Output "- MyOrg-permission already set to $($Permission) on calendar for $($user.userprincipalname)."  
    }
}  
}  