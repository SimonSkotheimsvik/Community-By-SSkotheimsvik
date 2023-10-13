<#
  .NOTES
  ===========================================================================
   Created on:   	28.09.2023
   Created by:   	Simon Skotheimsvik
   Filename:     	AAD-Users-ImportAttributesFromCSV.ps1
   Instructions:    https://skotheimsvik.no
  ===========================================================================
  
  .DESCRIPTION
    This script will import information about user accounts in AAD from CSV
#>

# Install and import the Microsoft Graph module
 #Install-Module -Name Microsoft.Graph
 Import-Module Microsoft.Graph

# Authenticate interactively (remember to aka.ms/pim first)
Connect-MgGraph -Scopes "User.ReadWrite.All"

# Define the CSV file path
$csvFilePath = "c:\temp\AAD-Users-Attributes.csv"

# Read the CSV file
$csvUsers = Import-Csv -Path $csvFilePath

# Attributes to check and update
$attributesToUpdate = @("GivenName", "Surname", "JobTitle", "Department", "CompanyName", "MobilePhone", "OfficeLocation", "PostalCode", "City", "Country", "UsageLocation", "Manager", "Id")

# Iterate through each user in the CSV and update Azure AD if needed
foreach ($csvUser in $csvUsers) {
    $userPrincipalName = $csvUser.UserPrincipalName

    # Retrieve the Azure AD user with all necessary attributes
    $azureADUser = Get-MgUser -Filter "userPrincipalName eq '$userPrincipalName'" -Property $attributesToUpdate

    if ($azureADUser) {
        # Get the user's Id
        $userId = $azureADUser.Id

        # Compare and update attributes
        $NoUpdatesForUser = $true

        foreach ($attribute in $attributesToUpdate) {
            if ($csvUser.$attribute -ne "") {  # Check if the CSV value is not empty
                if ($azureADUser.$attribute -ne $csvUser.$attribute) {
                    if ($attribute -eq "Manager") {
                        # Retrieve the manager's user object to get the manager's Id
                        $managerUser = Get-MgUser -Filter "userPrincipalName eq '$($csvUser.$attribute)'" -Property Id
                        $NewManager = @{
                            "@odata.id"="https://graph.microsoft.com/v1.0/users/$($managerUser.Id)"
                            }
                          
                         Set-MgUserManagerByRef -UserId $UserId -BodyParameter $NewManager
                         Write-Host "Updated $attribute for user: $userPrincipalName to $($csvUser.$attribute)" -ForegroundColor DarkYellow
                        }
                    else {
                        # All other attributes than the manager
                        $attributeValue = $csvUser.$attribute
                        $params = @{
                            "UserId" = $userId
                        }
                        $params[$attribute] = $attributeValue
                        Update-MgUser @params
                        Write-Host "Updated $attribute for user: $userPrincipalName to $attributeValue" -ForegroundColor DarkYellow
                    }
                $NoUpdatesForUser = $false
                }
            }
        }

        if ($NoUpdatesForUser -eq $true) {
            Write-Host "No updates for user: $userPrincipalName" -ForegroundColor Green
        }

    }
    else {
        Write-Host "User not found in Azure AD: $userPrincipalName" -ForegroundColor Cyan
    }
}

# Display a message indicating the update is complete
Write-Host "Userlist processing complete." -ForegroundColor Blue
