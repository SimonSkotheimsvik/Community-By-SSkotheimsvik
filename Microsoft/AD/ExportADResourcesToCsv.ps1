###############################################################################
#                                                                             #
# Script for exporting AD resources in given OU's to CSV file                 #
#                                                                             #
###############################################################################
#                                                                             #
# 2014.06.18 - Simon Skotheimsvik											  #
#                                                                             #
###############################################################################
    
Import-Module ac*

$path = "C:\Source\Scripts\"
$ADServer = "DC01.domain.local"
$OU = "ou=users,ou=mybusiness,dc=domain,dc=local"
$CSVUsers = $path + "ExportADResourcesToCsv-Users.csv"
$CSVComputers = $path + "ExportADResourcesToCsv-Computers.csv"

# USERS
Get-ADUser -server $ADServer -SearchBase $OU -Filter * -ResultSetSize 5000 -Properties EmailAddress, Company, Department, Title, Office, OfficePhone, MobilePhone, ipPhone, physicalDeliveryOfficeName, manager, msRTCSIP-Line, msRTCSIP-PrimaryUserAddress, homeDrive, homeDirectory, distinguishedName, proxyAddresses, lastLogonTimeStamp | Select givenName, surName, Name, SamAccountName, EmailAddress, Company, Department, Title, Office, OfficePhone, MobilePhone, ipPhone, physicalDeliveryOfficeName, manager, msRTCSIP-Line, msRTCSIP-PrimaryUserAddress, homeDrive, homeDirectory, distinguishedName, @{n = "lastLogonDate"; e = { [datetime]::FromFileTime($_.lastLogonTimestamp) } }, @{Name = "proxyAddresses"; expression = { $_.proxyAddresses -join ";" } } | export-csv $CSVUsers -Encoding "unicode"

# COMPUTERS
Get-ADComputer -server $ADServer -SearchBase $OU -Filter * -ResultSetSize 5000 -Properties cn, description, distinguishedName, operatingSystem, operatingSystemVersion, whenCreated, whenChanged, lastLogonTimestamp | Select @{n = "lastLogonDate"; e = { [datetime]::FromFileTime($_.lastLogonTimestamp) } }, cn, description, distinguishedName, DNSHostname, Enabled, operatingSystem, operatingSystemVersion, whenCreated, whenChanged | export-csv $CSVComputers -Encoding "unicode"