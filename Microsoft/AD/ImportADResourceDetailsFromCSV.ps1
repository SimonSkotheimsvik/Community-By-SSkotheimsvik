###############################################################################
#                                                                             #
# Script made for setting new variables in Active Directory 				  #
#                                                                             #
###############################################################################
#                                                                             #
# 2016.10.25 - Simon Skotheimsvik											  #
#                                                                             #
###############################################################################


#Import the Active Directory Module
Import-Module ac*

$path = "C:\Source\Scripts"
$importfile = "2023-07-06-ExportADResourcesToCsv-Users-updated.csv"
$fullpath = $path + "\" + $importfile
write-host "- Importing Users from "$fullpath

$testinputfile = test-path $fullpath

if ($testinputfile -eq $false) {
	write-host "- $fullpath is not found please create this file before continuing" -foregroundcolor red -backgroundcolor black
	exit 0
}

$users = $null
$users = import-csv $fullpath

if ($users -eq $null) {
	write-host "- No Users Found in Input File" -foregroundcolor red -backgroundcolor black
	exit 0
}
else {
	$count = $users | Measure-Object
    $count = $count.count
	write-host "- We have found " $count "Users to import"
}

###############################################################################
# CSV file with users found - Processing users                                #
###############################################################################
	
write-host "- Processing Users.....`n"
$index = 1

Foreach ($user in $users) {
	 
	write-host "- Processing User " $index " of " $count  -foregroundcolor Yellow -backgroundcolor Black
	# Decalaring User Variables from CSV file
	$givenName = $user.givenName
	$surName = $user.surName
	$displayName = $user.Name
	$SamAccountName = $user.SamAccountName
	$EmailAddress = ($user.EmailAddress).ToLower()
    if ($user.EmailAddress -ne "N/A") { $EmailAddress = $user.EmailAddress } else { $EmailAddress = $null }
    if ($user.Company -ne "N/A") { $company = $user.Company } else { $company = $null }
    if ($user.Department -ne "N/A") { $department = $user.Department } else { $department = $null }
    if ($user.Title -ne "N/A") { $title = $user.Title } else { $title = $null }
    if ($user.Office -ne "N/A") { $Office = $user.Office } else { $Office = $null }
    if ($user.Office -eq "Dublin") { 
        $c = "IE"
        $CO = "Ireland" 
        $countryCode = "372"
        $l = "Dublin"
    } else { 
        $c = $null
        $CO = $null 
        $countryCode = $null
        $l = $null
        }
    if ($user.physicalDeliveryOfficeName -ne "N/A") { $physicalDeliveryOfficeName = $user.physicalDeliveryOfficeName } else { $physicalDeliveryOfficeName = $null }
    if ($user.manager -ne "N/A") { $manager = $user.manager } else { $manager = $null }
	
	
	write-host "- Testing if $SamAccountName exists in AD"
	$adexist = get-aduser -identity $SamAccountName
	if ($adexist -ne $null) {
		write-host `t "- User" $SamAccountName "exists in AD"
		write-host `t "- Setting user variables $givenName, $surName, $displayName, $EmailAddress, $company, $department, $title, $Office, $manager "
#		set-aduser -identity $SamAccountName -givenName $givenName -surName $surName -DisplayName $displayName -EmailAddress $EmailAddress -company $company -Department $department -Title $title -Office $Office -Manager $manager #-Replace @{manager = $manager} 
		set-aduser -identity $SamAccountName -givenName $givenName -surName $surName -DisplayName $displayName -company $company -Department $department -Title $title -Office $Office -Manager $manager -Replace @{c = $c;CO = $CO;countryCode = $countryCode;l = $l} 
			
	}
	$index++
}

 
