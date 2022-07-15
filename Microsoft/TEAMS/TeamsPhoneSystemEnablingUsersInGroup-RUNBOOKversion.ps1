<#
  .NOTES
  ===========================================================================
   Created on:   	14.03.2022
   Created by:   	Simon Skotheimsvik
   Filename:     	TeamsPhoneSystemEnablingUsersInGroup-RUNBOOKversion.ps1
   Instructions:    https://skotheimsvik.blogspot.com/
  ===========================================================================
  
  .DESCRIPTION
    This script automates Teams voice enabling users based on group membership
	for the user. It uses telephoneNumber field in the user as Teams number. This
	must be formated in E.164 format.

	The script is also updating a Cosmos DB with info of users enabled for Teams
	Voice, which in turn feeds a Power BI report.

    The script is designed to run unattended in an Azure Runbook.

	TODO:
	- Change console reporting to runbook reporting.

  .EXAMPLE
    TeamsPhoneSystemEnablingUsersInGroup-RUNBOOKversion.ps1
#>

# Get the credential from Automation  
$credential = Get-AutomationPSCredential -Name 'TeamsPhoneEnablingScriptUser'  
$userName = $credential.UserName  
$securePassword = $credential.Password  
  
$psCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userName, $securePassword  

# Get the variables from Automation
$cosmosdbAccount = Get-AutomationVariable -Name 'cosmosdbAccount'
$cosmosdbCollectionId = Get-AutomationVariable -Name 'cosmosdbCollectionId'
$cosmosdbDatabase = Get-AutomationVariable -Name 'cosmosdbDatabase'
$cosmosdbSecondaryKey = Get-AutomationVariable -Name 'cosmosdbSecondaryKey'

# Connect to Microsoft Teams  
Connect-MicrosoftTeams -Credential $psCredential  
Connect-AzureAd -Credential $psCredential  

$secondaryKey = ConvertTo-SecureString -String $cosmosdbSecondaryKey -AsPlainText -Force
$cosmosDbContext = New-CosmosDbContext -Account $cosmosdbAccount -Database $cosmosdbDatabase -Key $secondaryKey
$cosmosDbCollectionId = $cosmosdbCollectionId
$Date = Get-Date -UFormat "%d.%m.%Y %R"

#Settings for Norway
$SecGroupObjectIdRTNO = @(
	'12345678-abcd-abcd-abcd-123456789abc'	# Display Name: Microsoft 365 - Phone System - Bergen
	'12345678-efgh-abcd-abcd-123456789abc'	# Display Name: Microsoft 365 - Phone System - Trondheim
)
$RoutingPolicyNO = "routingpolicy-no" 
$CallingPolicyNO = "CallingPolicy_NO_DVM"

# Settings for Vietnam
$SecGroupObjectIdRTVN = @(
	'12345678-ijkl-abcd-abcd-123456789abc'	# Display Name: Microsoft 365 - Phone System - VungTau
	'12345678-mnop-abcd-abcd-123456789abc'	# Display Name: Microsoft 365 - Phone System - Hanoi
)
$RoutingPolicyVN = "routingpolicy-vn" 

# Settings for Singapore
$SecGroupObjectIdRTSingapore = @(
	'12345678-qrst-abcd-abcd-123456789abc'	# Display Name: Microsoft 365 - Phone System - Jurong
)


# Declare Hash table for users and variables
$UsersToEnable = @{}
$ExistintTeamsUsersWithoutGroupActivation = @()
$Number = 1
$ExistingUsers = (Get-CsOnlineUser | ? { $_.EnterpriseVoiceEnabled }).UserPrincipalName 
# DENNE FIKK IKKE MED ALLE...... (Get-CsOnlineUser -Filter {(EnterpriseVoiceEnabled -eq $true)}).UserPrincipalName
$NumberOfExistingUsers = $ExistingUsers.count 


write-host `n"- Found $NumberOfExistingUsers existing voice enabled Teams users."`n -fore yellow

# Iterating all groups in Norway
ForEach ($GroupID in $SecGroupObjectIdRTNO) {
	# Reading information from Azure AD and Microsoft Teams
	$Group = Get-AzureADGroup -ObjectId $GroupID
	$Users = Get-AzureADGroupMember -ObjectId $Group.ObjectId -Top 10000

	# Calculations
	$NumberOfUsers = $Users.count
	$GroupDisplayName = $Group.DisplayName
	$TotalNumberOfUsers = $TotalNumberOfUsers + $NumberOfUsers

	write-host "- Found $NumberOfUSers users in group ""$GroupDisplayName""" -fore yellow

	# Add all users from $Group to $UsersToEnable
	$Users | ForEach-Object {
		$UserPrincipalName = $_.UserPrincipalName
		$DisplayName = $_.DisplayName
		$Country = "Norway"
		$UserPrincipalNameAndCountry = $UserPrincipalName + ";" + $Country
		$UsersToEnable.Add($UserPrincipalName, $UserPrincipalNameAndCountry)

		# Write userdata to CosmosDB for statistics
		$id = $([Guid]::NewGuid().ToString())
		$doc = [pscustomobject]@{
			id          = $id
			UPN         = $UserPrincipalName.ToLower()
			DisplayName = $DisplayName
			Date        = $Date
			Country     = $Country
		}
		$document = $doc | ConvertTo-json | Out-String
		# Sending data to Cosmos DB
		New-CosmosDbDocument -Context $cosmosDbContext -CollectionId $cosmosDbCollectionId -DocumentBody $document -PartitionKey $id -Encoding 'UTF-8'
	}
}


# Iterating all groups in Vungtau Vietnam
ForEach ($GroupID in $SecGroupObjectIdRTVN) {
	# Reading information from Azure AD and Microsoft Teams
	$Group = Get-AzureADGroup -ObjectId $GroupID
	$Users = Get-AzureADGroupMember -ObjectId $Group.ObjectId -Top 10000

	# Calculations
	$NumberOfUsers = $Users.count
	$GroupDisplayName = $Group.DisplayName
	$TotalNumberOfUsers = $TotalNumberOfUsers + $NumberOfUsers

	write-host "- Found $NumberOfUSers users in group ""$GroupDisplayName""" -fore yellow

	# Add all users from $Group to $UsersToEnable
	$Users | ForEach-Object {
		$UserPrincipalName = $_.UserPrincipalName
		$DisplayName = $_.DisplayName
		$Country = "Vietnam"
		$UserPrincipalNameAndCountry = $UserPrincipalName + ";" + $Country
		$UsersToEnable.Add($UserPrincipalName, $UserPrincipalNameAndCountry)

		# Write userdata to CosmosDB for statistics
		$id = $([Guid]::NewGuid().ToString())
		$doc = [pscustomobject]@{
			id          = $id
			UPN         = $UserPrincipalName.ToLower()
			DisplayName = $DisplayName
			Date        = $Date
			Country     = $Country
		}
		$document = $doc | ConvertTo-json | Out-String
		# Sending data to Cosmos DB
		New-CosmosDbDocument -Context $cosmosDbContext -CollectionId $cosmosDbCollectionId -DocumentBody $document -PartitionKey $id -Encoding 'UTF-8'
	}
}

# Iterating all groups in Singapore
ForEach ($GroupID in $SecGroupObjectIdRTSingapore) {
	# Reading information from Azure AD and Microsoft Teams
	$Group = Get-AzureADGroup -ObjectId $GroupID
	$Users = Get-AzureADGroupMember -ObjectId $Group.ObjectId -Top 10000

	# Calculations
	$NumberOfUsers = $Users.count
	$GroupDisplayName = $Group.DisplayName
	$TotalNumberOfUsers = $TotalNumberOfUsers + $NumberOfUsers

	write-host "- Found $NumberOfUSers users in group ""$GroupDisplayName""" -fore yellow

	# Add all users from $Group to $UsersToEnable
	$Users | ForEach-Object {
		$UserPrincipalName = $_.UserPrincipalName
		$DisplayName = $_.DisplayName
		$Country = "Singapore"
		$UserPrincipalNameAndCountry = $UserPrincipalName + ";" + $Country
		$UsersToEnable.Add($UserPrincipalName, $UserPrincipalNameAndCountry)

		# Write userdata to CosmosDB for statistics
		$id = $([Guid]::NewGuid().ToString())
		$doc = [pscustomobject]@{
			id          = $id
			UPN         = $UserPrincipalName.ToLower()
			DisplayName = $DisplayName
			Date        = $Date
			Country     = $Country
		}
		$document = $doc | ConvertTo-json | Out-String
		# Sending data to Cosmos DB
		New-CosmosDbDocument -Context $cosmosDbContext -CollectionId $cosmosDbCollectionId -DocumentBody $document -PartitionKey $id -Encoding 'UTF-8'
	}
}


# Iterate ExistingUsers and remove existing active teams phone system users from $UsersToEnable hash 
$ExistingUsers | ForEach-Object {
	$user = $_
	if ($UsersToEnable.ContainsKey($user)) {
		$UsersToEnable.Remove($user)
	}
	else {
		# Creates a table of Existing users in order to find voice enabled users not in the groups
		$ExistintTeamsUsersWithoutGroupActivation += $user
	}
}


$NumberOfNewUsers = $UsersToEnable.count
write-host `n"- New users to enable is $NumberOfNewUsers."  -fore yellow
write-host "- The new total number of Teams Voice users will be $TotalNumberOfUsers"`n -fore yellow

$UsersToEnable

# Iterate UsersToEnable hash table and activate new users for Teams phone system
# UsageLocation set based on Alpha-2 codes from https://www.iso.org/obp/ui/#search in order to get the corresponding number handling.
$UsersToEnable.GetEnumerator() | ForEach-Object	{
	$useridentity = '{0}' -f $_.key
	$country = ('{0}' -f $_.value).split(";")[1]
	write-host `t"- Teams Voice Enabling user $Number of $NumberOfNewUsers - $useridentity - $country"

	if ($country -eq "Norway") {
		$UsageLocation = "NO"
		$telephonenumber = ((Get-AzureADUser -Filter "UserPrincipalName eq '$useridentity'").telephoneNumber).replace(' ', '')
		Set-AzureADUser -ObjectId $useridentity -UsageLocation $UsageLocation
		#		Set-CsUser -identity $useridentity -EnterpriseVoiceEnabled $true -HostedVoiceMail $false
		Set-CsPhoneNumberAssignment -identity $useridentity -PhoneNumber $telephoneNumber -PhoneNumberType DirectRouting
		Set-CsPhoneNumberAssignment -identity $useridentity -EnterpriseVoiceEnabled $true
		Grant-CsOnlineVoiceRoutingPolicy -Identity $useridentity -PolicyName $RoutingPolicyNO
		Grant-CsTeamsCallingPolicy -Identity $useridentity -PolicyName $CallingPolicyNO		
		write-host `t"-- Norway settings applied"
	}
	elseif ($country -eq "Vietnam") {
		$UsageLocation = "VN"
		$telephonenumber = ((Get-AzureADUser -Filter "UserPrincipalName eq '$useridentity'").telephoneNumber).replace(' ', '')
		Set-AzureADUser -ObjectId $useridentity -UsageLocation $UsageLocation
		#		Set-CsUser -identity $useridentity -EnterpriseVoiceEnabled $true -HostedVoiceMail $false
		Set-CsPhoneNumberAssignment -identity $useridentity -PhoneNumber $telephoneNumber -PhoneNumberType DirectRouting
		Set-CsPhoneNumberAssignment -identity $useridentity -EnterpriseVoiceEnabled $true
		Grant-CsOnlineVoiceRoutingPolicy -Identity $useridentity -PolicyName $RoutingPolicyVN
		Grant-CsTeamsCallingPolicy -Identity $useridentity -PolicyName $CallingPolicyNO
		write-host `t"-- Vietnam settings applied"
	}
	elseif ($country -eq "Singapore") {
		$UsageLocation = "SG"
		$telephonenumber = ((Get-AzureADUser -Filter "UserPrincipalName eq '$useridentity'").telephoneNumber).replace(' ', '')
		Set-AzureADUser -ObjectId $useridentity -UsageLocation $UsageLocation
		Set-CsPhoneNumberAssignment -Identity $useridentity -PhoneNumber $telephonenumber -PhoneNumberType OperatorConnect
		write-host `t"-- Singapore settings applied"
	}

	#    Get-CsOnlineUser -Identity $useridentity | select InterpretedUserType,OnPremLineURI,HostedVoiceMail,EnterpriseVoiceEnabled,LineURI,SipAddress,VoicePolicy,TeamsCallingPolicy,TeamsInteropPolicy,TeamsUpgradeEffectiveMode,TeamsUpgradePolicy,OnlineVoiceRoutingPolicy,TenantDialPlan
	$Number = $Number + 1
}

write-host `n"- Operation completed. Please note: It can take some time before the users see the change in their client." -fore green

$NumberOfExistingUsers = (Get-CsOnlineUser | ? { $_.EnterpriseVoiceEnabled }).count 

write-host `n"- Found $NumberOfExistingUsers voice enabled Teams users." -fore yellow

if ($NumberOfExistingUsers -gt $TotalNumberOfUsers) {
	write-host "-- The difference between the $NumberOfExistingUsers voice enabled Teams users and the planned $TotalNumberOfUsers are caused by deleted users still voice enabled."
	for ($i = 0; $i -lt $ExistintTeamsUsersWithoutGroupActivation.length; $i++) {
		write-host `t"-- Deleted user still counted: " $ExistintTeamsUsersWithoutGroupActivation[$i]
	}
}
write-host `n


 
# Disconnect from Microsoft Teams  
Disconnect-MicrosoftTeams 