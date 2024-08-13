<#
  .NOTES
  ===========================================================================
   Created on:   	13.08.2024
   Created by:   	Simon Skotheimsvik
   Filename:     	OneDriveForBusiness PreProvisioning.ps1
   Info:          https://skotheimsvik.no
  ===========================================================================
  
  .DESCRIPTION
    Doing migrations using Migration Wizard to new user accounts, the OneDrive for Business sites must be pre-provisioned.
    Requirement for Microsoft.Online.SharePoint.Powershell is Windows PowerShell up to version 5.0
    Can be problematic in VSCode. Use Windows PowerShell ISE
#>


# Connect to the SharePoint Online service using the admin URL
Connect-SPOService -Url https://yourcompany-admin.sharepoint.com

# Define an array of user emails for whom OneDrive for Business sites will be provisioned
$users = @(
    "user.one@company.com", 
    "user.two@company.com", 
    "user.three@company.com", 
    "user.four@company.com" 
)

# Loop through each user in the $users array
foreach ($user in $users) {
    # Request to pre-provision a OneDrive for Business site for the current user
    # The -NoWait parameter allows the command to return immediately without waiting for the operation to complete
    Request-SPOPersonalSite -UserEmails $user -NoWait
    
    # Optional: Provide feedback in the console that the request was made
    Write-Host "OneDrive provisioning requested for $user" -ForegroundColor Green
}