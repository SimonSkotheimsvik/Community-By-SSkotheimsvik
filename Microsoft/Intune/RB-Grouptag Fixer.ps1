<#
    .SYNOPSIS
    Created on:     01.06.2023
    Modified on:    05.01.2024
    Created by:     CloudWay, Simon Skotheimsvik
    Info:           Group Tag Fixer
    Version:        1.1
    
    .DESCRIPTION
    Function App for fixing Group tag on Windows Autopilot devices where this is missing.
    This code is setting correct group tag on autopilot computers based on computer name.
#>

#region Variables
$TenantId = Get-AutomationVariable -Name 'tenantid'
$GroupTagDefinition = "UCC Autopilot"

$csvContent = @"
DevicePrefix;Dept;ScopeTag;GroupTag;AutopilotProfileGuid
APC-;APC;UCC - APC Managed Devices;UCC-APC;72b2d424-33b4-4cdf-8689-90700c362fc3
CS-;Computer Science;UCC - Computer Science Managed Devices;UCC-CS;a371eabb-8808-4cca-9058-47b990c59ef0
CUBS-;Business and Law;UCC - CUBS Managed Devices;UCC-CUBS;da05ac92-c550-4d8b-92cf-54d7dbe3b593
DENT-;Dentistry;UCC - Dentistry Managed Devices;UCC-DENT;a9cacbfe-304c-4a14-9a00-b19186f5998c
ENG-;Engineering;UCC - Engineering Managed Devices;UCC-ENG;bb0ddd0d-5a98-40f4-8c0e-407af06bd8c5
AVMS-;IT Services AVMS;UCC - IT Services AVMS Windows Managed Devices;UCC-AVMS;98dd8ac3-ef2a-455c-9c99-8f41728f45a9
SIT-;IT Services SIT;UCC - IT Services SIT Windows Managed Devices;UCC-SIT;a517f67e-4344-4b9d-b481-4205c8145f1d
ITSM-;"IT Services Staff ";UCC - IT Services Windows Managed Devices;UCC-ITSM;" "
LAW-;Law;UCC - Law Managed Devices;UCC-LAW;ac774473-653c-4860-b6fb-88629989c474
LIB-;Library;UCC - Library Managed Devices;UCC-LIB;7367e07e-c0d9-4612-8fbe-a5384c654f7a
MED-;Medicine;UCC - Medicine Managed Devices;UCC-MED;7e3621cc-5957-4f66-a622-b5813f88c2cb
SONM-;Midwifery;UCC - Nursing and Midwifery Managed Devices;UCC-SONM;f6692965-3675-482e-a7aa-77d8f5a22032
SEFS-;Science;UCC - SEFS Managed Devices;UCC-SEFS;e75e7c22-8b3a-4726-8de9-5c18bd7c3a87
"@

$GroupTagInfo = $csvContent | ConvertFrom-Csv -delimiter ";"

#endregion Variables

#region Authentication
Connect-AzAccount -Identity -TenantId $TenantId
$token = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
Connect-MgGraph -AccessToken $token.Token
write-output "Authentication finished"
#endregion Authentication

#region Device traversal
foreach ($Group in $GroupTagInfo) {
    # Get variables from CSV for current group
    $DevicePrefix  = $Group.DevicePrefix
    $DeviceTargetGroupTag = $Group.GroupTag

    # Search all Autopilot devices starting with Prefix and has Zero Touch Device ID
    $Devices = Get-MgDevice -Search "displayName:$DevicePrefix" -ConsistencyLevel eventual -All | Where-Object { $_.PhysicalIds -match '\[ZTDID\]' }

    if ($Devices.count -gt 0) {
        Write-Output "$($Devices.count) devices with prefix $DevicePrefix"

        # Iterate alle devices found where name starting with Prefix
        foreach ($Device in $Devices) {
            # Get variables from the Autopilot device
            $DeviceDisplayName = $Device.DisplayName
            $AutopilotZTDID = ($Device.PhysicalIds | Select-String -Pattern '\[ZTDID\]:(.*)').Matches.Groups[1].Value
            try {
                $DeviceGroupTag = ($Device.PhysicalIds | Select-String -Pattern '\[OrderId\]:(.*)').Matches.Groups[1].Value
            }
            catch {
                Write-Error "$($DeviceDisplayName) is missing grouptag."
                $DeviceGroupTag = ""
            }

            # Check if current Group tag is Ok
            if ($DeviceTargetGroupTag -ne $DeviceGroupTag) {
                Write-Warning "$($DeviceDisplayName) has grouptag ""$($DeviceGroupTag)"" not matching target grouptag ""$($DeviceTargetGroupTag)"". Device will be updated."
                
                # Update Autopilot device with new Group tag
                $params = @{
                    groupTag = $DeviceTargetGroupTag
                }
                Update-MgDeviceManagementWindowAutopilotDeviceIdentityDeviceProperty -WindowsAutopilotDeviceIdentityId $AutopilotZTDID -BodyParameter $params
            }
            else {
                Write-Output "$($DeviceDisplayName) has grouptag ""$($DeviceGroupTag)"". No change required."
            }

            $Device = $null
            $DeviceDisplayName = $null
            $DeviceGroupTag = $null
            $AutopilotZTDID = $null
        }
    }
    else {
        Write-Output "$($Devices.count) devices with prefix $DevicePrefix"
    }
    $Devices = $null     
}
#endregion Device traversal