<#
    .SYNOPSIS
    Created on:     01.06.2023
    Modified on:    12.01.2024
    Created by:     Simon Skotheimsvik
    Info:           https://skotheimsvik.no
    Version:        1.1.1
    
    .DESCRIPTION
    Automatic set Group tag on Autopilot devices based on computer name.
    Script designed for running in Azure Automation Account using managed identity.#>

#region Variables
$TenantId = Get-AutomationVariable -Name 'aa-no-grouptag-tenantid'

$csvContent = @"
DevicePrefix;GroupTag
SE-;Device-SE
NO-;Device-NO
DK-;Device-DK
FI-;Device-FI
DE-;Device-DE
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

    # Search all Autopilot devices starting with Prefix and has Zero Touch Device ID (Autopilot devices)
    $Devices = Get-MgBetaDevice -Search "displayName:$DevicePrefix" -ConsistencyLevel eventual -All | Where-Object { $_.PhysicalIds -match '\[ZTDID\]' }

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
                Update-MgBetaDeviceManagementWindowAutopilotDeviceIdentityDeviceProperty -WindowsAutopilotDeviceIdentityId $AutopilotZTDID -BodyParameter $params
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