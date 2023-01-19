<#
  .NOTES
  ===========================================================================
   Created on:   	13.01.2023
   Created by:   	Simon Skotheimsvik
   Filename:     	Exchange-ListMailboxes.ps1
   Instructions:    https://github.com/SimonSkotheimsvik/Community-By-SSkotheimsvik/
  ===========================================================================
  
  .DESCRIPTION
    This script will list details of all mailboxes on Exchange server
    
  .EXAMPLE
    Exchange-ListMailboxes.ps1 
#>


$(Foreach ($mailbox in Get-Recipient -ResultSize Unlimited){
  $Stat = $mailbox | Get-MailboxStatistics | Select TotalItemSize,ItemCount,TotalDeletedItemSize,DeletedItemCount,Servername,Database
      New-Object PSObject -Property @{
      FirstName = $mailbox.FirstName
      LastName = $mailbox.LastName
      DisplayName = $mailbox.DisplayName
      TotalItemSize = $Stat.TotalItemSize
      TotalDeletedItemSize = $Stat.TotalDeletedItemSize
      ItemCount = $Stat.ItemCount
      DeletedItemCount = $Stat.DeletedItemCount
      Servername = $Stat.Servername
      Database = $Stat.Database
      PrimarySmtpAddress = $mailbox.PrimarySmtpAddress
      Alias = $mailbox.Alias
      EmailAddresses = $mailbox.EmailAddresses
      RecipientType = $mailbox.RecipientType
      }
  }) | Select RecipientType,FirstName,LastName,DisplayName,TotalItemSize,ItemCount,TotalDeletedItemSize,DeletedItemCount,Servername,Database,PrimarySmtpAddress,Alias,@{Name=“EmailAddresses”;Expression={$_.EmailAddresses | Where-Object {$_.PrefixString -ceq “smtp”} | ForEach-Object {$_.SmtpAddress}}} | Export-CSV .\Exchange-ListMailboxes.csv -Encoding UTF8 -NoTypeInformation