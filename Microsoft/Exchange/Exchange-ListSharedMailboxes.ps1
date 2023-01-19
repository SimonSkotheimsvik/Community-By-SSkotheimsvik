<#
  .NOTES
  ===========================================================================
   Created on:   	19.01.2023
   Created by:   	Simon Skotheimsvik
   Filename:     	Exchange-ListSharedMailboxes.ps1
   Instructions:    https://github.com/SimonSkotheimsvik/Community-By-SSkotheimsvik/
  ===========================================================================
  
  .DESCRIPTION
    This script will list Shared mailboxes on Exchange on-premises
#>

$CSVFile = ".\Exchange-ListSharedMailboxes.csv"
if (Test-Path $CSVFile) {
    Remove-Item $CSVFile
}


$SharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited | select DisplayName,Alias,UserPrincipalName,PrimarySmtpAddress,ServerName,Database,@{Name=“EmailAddresses”;Expression={$_.EmailAddresses | Where-Object {$_.PrefixString -ceq “smtp”} | ForEach-Object {$_.SmtpAddress}}}

$(Foreach ($mailbox in $SharedMailboxes){
$Permissions = Get-MailboxPermission $mailbox.UserPrincipalName | select user,@{Name=“accessrights”;Expression={$_.accessrights }},IsInherited,Deny | where { ($_.User -notlike 'NT AUTHORITY\*') }
    $(Foreach ($Permission in $Permissions){
        New-Object PSObject -Property @{
        DisplayName = $mailbox.DisplayName
        Alias = $mailbox.Alias
        UserPrincipalName = $mailbox.UserPrincipalName
        PrimarySmtpAddress = $mailbox.PrimarySmtpAddress
        EmailAddresses = $mailbox.EmailAddresses
        ServerName = $mailbox.ServerName
        Database = $mailbox.Database
        User = $Permission.user
        AccessRights = $Permission.accessrights
        } | Select DisplayName,Alias,UserPrincipalName,PrimarySmtpAddress,ServerName,Database,User,AccessRights,EmailAddresses | Export-CSV $CSVFile -Encoding UTF8 -NoTypeInformation -Append
    })
}) 