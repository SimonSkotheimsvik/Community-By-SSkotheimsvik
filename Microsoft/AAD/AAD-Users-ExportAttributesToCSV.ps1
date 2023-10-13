<#
  .NOTES
  ===========================================================================
   Created on:   	28.09.2023
   Created by:   	Simon Skotheimsvik
   Filename:     	AAD-Users-ExportAttributesToCSV.ps1
   Instructions:    https://skotheimsvik.no
  ===========================================================================
  
  .DESCRIPTION
    This script will export information about user accounts in AAD to CSV
#>


# Install and import the Microsoft Graph module
#Install-Module -Name Microsoft.Graph
Import-Module Microsoft.Graph

# Authenticate interactively (remember to aka.ms/pim first)
Connect-MgGraph -Scopes "User.Read.All"

# Define the output CSV file path
$csvFilePath = "c:\temp\AAD-Users-Attributes.csv"

# Retrieve all users from Azure AD using Microsoft Graph
$users = Get-MgUser -All -Property Id, UserPrincipalName, GivenName, Surname, JobTitle, Department, CompanyName, MobilePhone, OfficeLocation, PostalCode, City, Country, UsageLocation -Expand Manager | Select-Object Id, UserPrincipalName, GivenName, Surname, JobTitle, Department, CompanyName, MobilePhone, OfficeLocation, PostalCode, City, Country, UsageLocation, @{Name='Manager'; Expression={$_.Manager.AdditionalProperties.userPrincipalName}}

# Export the user details to a CSV file
$users | Export-Csv -Path $csvFilePath -NoTypeInformation

# Display a message indicating the export is complete
Write-Host "User details exported to $csvFilePath."
