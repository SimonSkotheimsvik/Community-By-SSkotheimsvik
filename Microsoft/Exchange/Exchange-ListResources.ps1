<#
  .NOTES
  ===========================================================================
   Created on:   	19.01.2023
   Created by:   	Simon Skotheimsvik
   Filename:     	Exchange-ListResources.ps1
   Instructions:    https://github.com/SimonSkotheimsvik/Community-By-SSkotheimsvik/
  ===========================================================================
  
  .DESCRIPTION
    This script will list details on Exchange resource objects on-premises
#>

Get-Mailbox -ResultSize Unlimited | Where-object { $_.IsResource -eq 'true' } | Select DisplayName,Alias,UserPrincipalName,PrimarySmtpAddress,RecipientType,RecipientTypeDetails,ResourceType,ServerName,Database,@{Name=“EmailAddresses”;Expression={$_.EmailAddresses | Where-Object {$_.PrefixString -ceq “smtp”} | ForEach-Object {$_.SmtpAddress}}} | Export-CSV .\Exchange-ListResources.csv -Encoding UTF8 -NoTypeInformation