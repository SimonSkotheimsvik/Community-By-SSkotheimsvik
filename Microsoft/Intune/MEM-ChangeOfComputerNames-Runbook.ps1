<#
  .NOTES
  ===========================================================================
   Created on:   	09.05.2022
   Created by:   	Simon Skotheimsvik
   Filename:     	MEM-ChangeOfComputerNames-Runbook.ps1
   Instructions:    https://skotheimsvik.no/rename-computers-with-countrycode-in-intune
  ===========================================================================
  
  .DESCRIPTION
    This script uses the Graph API to bulk rename Windows devices. It can for 
    example be used in a scenario where autopilot default naming has been used
    and a new standardised naming convention has been agreed upon. This Script
    will use the Country Code from the owning users Azure Account. It can be
    modified to use other user variables as well.

    The script is designed to run unattended in an Azure Runbook.

    Prerequisits:
    - Az.Storage
    
  .EXAMPLE
    MEM-ChangeOfComputerNames-Runbook.ps1 

#>

$GLOBAL:DebugPreference = "Continue"

$Countries = @{
    Norway    = "NO"
    Vietnam   = "VN"
    Brazil    = "BR"
    Chile     = "CL"
    Croatia   = "HR"
    India     = "IN"
    Italy     = "IT"
    Poland    = "PL"
    Romania   = "RO"
    Singapore = "SG"
    Canada    = "CA"
}

# CONNECT TO GRAPH WITH AZURE APP-REGISTRATION
$TenantId = Get-AutomationVariable -Name 'Computer_Rename_TenantID'
$ClientId = Get-AutomationVariable -Name 'Computer_Rename_ClientID'
$ClientSecret = Get-AutomationVariable -Name 'Computer_Rename_ClientSecret'

# Create a hashtable for the body, the data needed for the token request
# The variables used are explained above
$Body = @{
    'tenant'        = $TenantId
    'client_id'     = $ClientId
    'scope'         = 'https://graph.microsoft.com/.default'
    'client_secret' = $ClientSecret
    'grant_type'    = 'client_credentials'
}

# Assemble a hashtable for splatting parameters, for readability
# The tenant id is used in the uri of the request as well as the body
$Params = @{
    'Uri'         = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    'Method'      = 'Post'
    'Body'        = $Body
    'ContentType' = 'application/x-www-form-urlencoded'
}

$AuthResponse = Invoke-RestMethod @Params

$Headers = @{
    'Authorization' = "Bearer $($AuthResponse.access_token)"
}

# Connect-MgGraph with Token in order to be able to post a computer renaming
$connection = Invoke-RestMethod `
    -Uri https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token `
    -Method POST `
    -Body $body
 
$token = $connection.access_token
Connect-MgGraph -AccessToken $token

write-output "Authentication finished"

############################################################
# ROUTINE FOR RENAMING USERS AUTOPILOT DEVICES
############################################################

foreach ($CountryCode in $Countries.keys) {
    write-output "Working on country $CountryCode"
    $Country = $CountryCode
    $CountryCode = $($Countries[$Country])
    $MaxSerialLength = (15 - $CountryCode.get_Length()) - 1 #Max 15 characters allowed in devicename. Calculate length of serial# part.
    $userList = $Null

    # Get all users with the current country code. Use paging in order to get more than 999 which is max pr query
    $UsersURL = 'https://graph.microsoft.com/v1.0/users?$filter=startswith(country,''' + $Country + ''')&$top=999'
    While ($UsersURL -ne $Null) {
        $data = (Invoke-WebRequest -Headers $Headers -Uri $UsersURL -UseBasicParsing) | ConvertFrom-Json
        $userList += $data.Value
        $UsersURL = $data.'@Odata.NextLink'    
    }

    # Get all managed devices for each user
    foreach ($User in $UserList) {
        $upn = $User.userPrincipalName
        write-output "- Focus on user $upn"
        $DeviceList = $Null
        $deviceURL = 'https://graph.microsoft.com/v1.0/users/' + $User.userPrincipalName + '/managedDevices?$filter=startswith(operatingSystem,''Windows'')'
        $DeviceList = (Invoke-RestMethod -Uri $deviceURL -Headers $Headers).value
        $NoOfDevices = $DeviceList.Count
        write-output "- $NoOfDevices device(s) found"

        foreach ($Device in $DeviceList) {
            $CurrentDeviceName = $Device.deviceName
            write-output "--- Focus on device $CurrentDeviceName"
            $OS = $Device.operatingSystem
            $DeviceID = $Device.id
            $FullSerial = $Device.serialNumber

            # Max 15 characters allowed in devicename - Some devices have to long serialnumber
            if ($FullSerial.get_Length() -gt $MaxSerialLength) {
                $DeviceSerial = $FullSerial.substring($FullSerial.get_Length() - $MaxSerialLength)
                write-output "---- Serial too long - shortened!"
            }
            else {
                $DeviceSerial = $FullSerial
            }
            # Calculates new devicename in format NO-12345678
            $CalculatedDeviceName = $CountryCode.ToUpper() + '-' + $DeviceSerial
            
            # Virtual computers have the text "SerialNumber" as serialnumber...
            if (($CurrentDeviceName -ne $CalculatedDeviceName) -and ($DeviceSerial -ne "SerialNumber")) {
                write-warning "---- Device $CurrentDeviceName needs to be renamed to $CalculatedDeviceName"
                # Calculate graph api url's
                $Resource = "deviceManagement/managedDevices/$DeviceID/setDeviceName"
                $GraphApiVersion = "beta"
                $URI = "https://graph.microsoft.com/$GraphApiVersion/$($Resource)"

                $JSONPayload = @{
                    "deviceName" = $CalculatedDeviceName
                }

                $convertedJSONPayLoad = $JSONPayload | ConvertTo-Json
                
                #Send change to Graph.
                Invoke-MgGraphRequest -Uri $URI -Method POST -Body $convertedJSONPayLoad -Verbose -ErrorAction Continue
            }
            else {
                write-output "---- $CurrentDeviceName will not be renamed"
            }
        }
    }
}

