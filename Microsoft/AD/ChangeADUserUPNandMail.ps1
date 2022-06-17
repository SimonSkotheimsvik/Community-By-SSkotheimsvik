###############################################################################
#                                                                             #
# Script made for setting new UPN, SIP and Mail addresses in Active Directory #
# Main purpose is to get a clean AD before introducing O365 integration       #
# https://github.com/SimonSkotheimsvik/Community-By-SSkotheimsvik             #
#                                                                             #
###############################################################################
#                                                                             #
# Tested on customer running AD with DirSync integration on O365              #
# 1. Export AD users to CSV and let customer manually build new UPN/SIP/Mail  #
# 2. Run this script with modified CSV to update users with new UPN/SIP/Mail  #
#                                                                             #
###############################################################################
#                                                                             #
# 2016.10.25 - Simon Skotheimsvik											  #
#                                                                             #
###############################################################################


#Import the Active Directory Module
Import-Module ac*

$path = "C:\Source\Scripts"
$importfile = "ChangeADUserUPNandMail.csv"
$fullpath = $path + "\" + $importfile
write-host "- Importing Users from "$fullpath


$testinputfile = test-path $fullpath

if ($testinputfile -eq $false)
	{
		 write-host "- $fullpath is not found please create this file before continuing" -foregroundcolor red -backgroundcolor black
		 exit 0
	}

$users = $null
$users = import-csv $fullpath

if ($users -eq $null)
	{
		 write-host "- No Users Found in Input File" -foregroundcolor red -backgroundcolor black
		 exit 0
	}
else
	{
		 $count = $users.count
		 write-host "- We have found " $count "Users to import"
	}

###############################################################################
# CSV file with users found - Processing users                                #
###############################################################################
	
write-host "- Processing Users.....`n"
$index = 1

Foreach ($user in $users)
	{
	 
	 write-host "- Processing User " $index " of " $count  -foregroundcolor Yellow -backgroundcolor Black
	 # Decalaring User Variables from CSV file
	 $SamAccountName = $user.SamAccountName
	 $EmailAddress = $user.EmailAddress
	 $NewUPN = $user.NewUPN
		$NewUPNPrefix = $NewUPN.Split("@")[0]
		$NewUPNSuffix = "@"+$NewUPN.Split("@")[1]
	 $NewSIP = "sip:"+$NewUPN
	 $NewSMTPproxy = "SMTP:"+$NewUPN
	 $oldSMTPproxy = "SMTP:"+$EmailAddress
	 
	
	write-host "- Testing if $samaccountname exists in AD"
	 $adexist = get-aduser -identity $SamAccountName
	 if ($adexist -ne $null)
		{
			write-host `t"- User " $samaccountname " exists in AD"

		# Decalaring the new ProxyAddresses and add them to an Array
			$ProxyAddresses = Get-ADUser -Identity $SamAccountName -Properties ProxyAddresses | Select-Object ProxyAddresses -ExpandProperty ProxyAddresses
			$ProxyAddressesArray = @()	#Declare the array

			Foreach ($Paddress in $ProxyAddresses)
				{
				# Finding Proxy Address Type
				$PaddressType = $Paddress.Split(":")[0]
		 
				if ($PaddressType -eq "sip")
					{
					#Change to new SIP address
					$ProxyAddressesArray += $NewSIP
					}
				elseif ($PaddressType -clike "SMTP")
					{
					#Set old-Primary as secondary address if its not equal the New SMTPProxy
					if ($Paddress -ne $NewSMTPproxy)
						{
						$ProxyAddressesArray += $Paddress.tolower()
						}
					#Change to new primary address
					$ProxyAddressesArray += $NewSMTPproxy
					}
				elseif ($Paddress -clike $NewSMTPproxy.tolower())
					{
					#Remove "new primary address" as a secondary address
					}
				else
					{
					$ProxyAddressesArray += $Paddress
					}
				}
				
			write-host "------------------------"

			write-host "Setting new ProxyAddresses"
				# remove old proxy addresses from AD
			    set-aduser -identity $SamAccountName -Clear proxyAddresses
				# iterate array and add new proxyAddresses
				Foreach ($PaddressA in $ProxyAddressesArray)
					{
					set-aduser -identity $SamAccountName -Add @{proxyAddresses = "$PaddressA"}
					write-host `t  $PaddressA
					}

			write-host "Setting new Mail Address "
				set-aduser -identity $SamAccountName -email $NewUPN
				write-host `t $NewUPN
			
			write-host "Setting new UPN"
				set-aduser -identity $SamAccountName -UserPrincipalName $NewUPN
				write-host `t $NewUPN
				#write-host `t`t $NewUPNPrefix
				#write-host `t`t $NewUPNSuffix

			write-host "Setting new SIP"
				set-aduser -identity $SamAccountName -replace @{'msRTCSIP-PrimaryUserAddress' = $NewSIP}
				write-host `t $NewSIP
		}
	$index++
	}

 
