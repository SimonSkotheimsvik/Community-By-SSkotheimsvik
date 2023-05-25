<#
  .NOTES
  ===========================================================================
   Created on:   	09.05.2022
   Modified on:     25.05.2023
   Created by:   	Simon Skotheimsvik
   Filename:     	Intune-ChangeOfComputerNames-Runbook-ManagedIdentity.ps1
   Instructions:    https://skotheimsvik.no/rename-computers-with-countrycode-in-intune
  ===========================================================================
  
  .DESCRIPTION
    This script uses the Graph API to bulk rename Windows devices. It can
    be used in a scenario where autopilot default naming has been used and
    a new standardised naming convention has been agreed upon.
    This Script will use the Country Code from the owning users Azure Account.
    It can be modified to use other user variables as well.

    The script is designed to run unattended in an Azure Runbook.
#>

#region Variables
$GLOBAL:DebugPreference = "Continue"
$TenantId = Get-AutomationVariable -Name 'CWS-ComputerNamingStandards-TenantId'

$Countries = @{
    Norway          = "NO"
    Vietnam         = "VN"
    Brazil          = "BR"
    Chile           = "CL"
    Croatia         = "HR"
    India           = "IN"
    Italy           = "IT"
    Poland          = "PL"
    Romania         = "RO"
    Singapore       = "SG"
    Canada          = "CA"
    "United States" = "US"
}
#endregion Variables

#region Connect to Graph with Managed Identity Token
Connect-AzAccount -Identity -ErrorAction Stop | Out-Null
 
$token = (Get-AzAccessToken -ResourceTypeName MSGraph).token # Get-PnPAccessToken
$Headers = @{
    "Content-Type" = "application/json"
    Authorization  = "Bearer $token"
}

write-output "Authentication finished"
#endregion Connect

#region Routine for renaming users Autopilot devices
foreach ($Country in $Countries.keys) {
    write-output "Working on country $Country"
    $ISO3166Alpha2CountryCode = $($Countries[$Country])
    $MaxSerialLength = (15 - $ISO3166Alpha2CountryCode.get_Length()) - 1 #Max 15 characters allowed in devicename. Calculate length of serial# part.
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
            $CalculatedDeviceName = $ISO3166Alpha2CountryCode.ToUpper() + '-' + $DeviceSerial

            # Virtual computers have the text "SerialNumber" as serialnumber...
            if (($CurrentDeviceName -ne $CalculatedDeviceName) -and ($DeviceSerial -ne "SerialNumber")) {
                write-warning "---- Device $CurrentDeviceName will be renamed to $CalculatedDeviceName"
                $URI = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$DeviceID/setDeviceName"
                $JSONPayload = @{
                    "deviceName" = $CalculatedDeviceName
                }
                $convertedJSONPayLoad = $JSONPayload | ConvertTo-Json

                Invoke-RestMethod -Uri $URI -Method POST -Body $convertedJSONPayLoad -Headers $Headers
            }
            else {
                write-output "---- $CurrentDeviceName will not be renamed"
            }
        }
    }
}
#endregion Routine