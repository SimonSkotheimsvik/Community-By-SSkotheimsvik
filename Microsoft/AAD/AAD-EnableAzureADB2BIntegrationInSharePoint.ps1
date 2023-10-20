<#
  .NOTES
  ===========================================================================
   Created on:   	20.10.2023
   Created by:   	Simon Skotheimsvik
   Filename:     	AAD-EnableAzureADB2BIntegrationInSharePoint.ps1
   Instructions:    https://skotheimsvik.no
  ===========================================================================
  
  .DESCRIPTION
    This script will enable Entra ID B2B integration for SharePoint and OneDrive for Business.
#>

# Get module for SharePoint Online
# install-module -Name Microsoft.Online.SharePoint.Powershell
import-module -Name Microsoft.Online.SharePoint.Powershell

# Connect to your SharePoint Admin Center
Connect-SPOService -Url https://m365x73910067-admin.sharepoint.com/

# Check current setting
Get-SPOTenant | ft EnableAzureADB2BIntegration

# Sett Azure AD B2B Integration
Set-SPOTenant -EnableAzureADB2BIntegration $true