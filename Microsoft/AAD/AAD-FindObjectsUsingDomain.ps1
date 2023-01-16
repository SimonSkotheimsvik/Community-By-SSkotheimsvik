<#
  .NOTES
  ===========================================================================
   Created on:   	13.01.2023
   Created by:   	Simon Skotheimsvik
   Filename:     	FindObjectsUsingDomain.ps1
   Instructions:    https://skotheimsvik.no
  ===========================================================================
  
  .DESCRIPTION
    This script will find users and groups using a custom domain in AAD
#>

# Authenticate
$conn = Connect-MgGraph -Scopes "User.Read.All, Group.Read.All"
Select-MgProfile -name beta

# Define domain name for filtering
$domain = "skotheimsvik.no"

# Get users filtered on UPN, MAIL, IMADDRESSES and PROXYADDRESSES
$Users = Get-MgUser -All | Where-Object {$_.UserPrincipalName -like "*@$domain" -or $_.Mail -like "*@$domain" -or $_.ImAddresses -like "*@$domain" -or $_.ProxyAddresses -like "*@$domain"} | Select-Object Id, DisplayName, UserPrincipalName, Mail, imAddresses, ProxyAddresses
$Users | measure
$Users | Out-GridView
$Users | Export-Csv -Encoding utf8 "C:\Temp\$domain-Users.csv"

# Get groups filtered on MAIL
$Groups = Get-MgGroup -All | Where-Object {$_.mail -like "*$domain"} | Select-Object Id, DisplayName, Description, mail
$Groups | measure
$Groups | Out-GridView
$Groups | Export-Csv -Encoding utf8 "C:\Temp\$domain-Groups.csv"