<#
    .SYNOPSIS
    Created on:     01.06.2023
    Modified on:    12.01.2024
    Created by:     Simon Skotheimsvik
    Info:           https://skotheimsvik.no
    Version:        1.1.3
    
    .DESCRIPTION
    Automatic set Group tag on Autopilot devices based on computer name.
    Script designed for running in Azure Automation Account using managed identity.#>

#region Variables
$TenantId = Get-AutomationVariable -Name 'aa-no-grouptag-tenantid'

$csvContent = @"
DevicePrefix;GroupTag
SE-;DeviceSE
NO-;DeviceNO
DK-;DeviceDK
FI-;DeviceFI
DE-;DeviceDE
"@

$GroupTagInfo = $csvContent | ConvertFrom-Csv -delimiter ";"

#endregion Variables

#region Authentication
Connect-MgGraph -Identity #-TenantId $TenantId
write-output "Authentication finished"
#endregion Authentication

#region Device traversal
foreach ($Group in $GroupTagInfo) {
    # Get variables from CSV for current group
    $DevicePrefix = $Group.DevicePrefix
    $DeviceTargetGroupTag = $Group.GroupTag

    # Search all Autopilot devices starting with Prefix and has Zero Touch Device ID (Autopilot devices)
    $Devices = Get-MgBetaDevice -Filter "startsWith(displayName, '$DevicePrefix')" -ConsistencyLevel eventual -All | Where-Object { $_.PhysicalIds -match '\[ZTDID\]' }

    if ($Devices.count -gt 0) {
        Write-Output "$($Devices.count) devices with prefix $DevicePrefix"

        # Iterate alle devices found where name starting with Prefix
        foreach ($Device in $Devices) {
            # Get variables from the Autopilot device
            $ReturnBodyTemp = New-Object -TypeName PSObject     # New JSON object for logging
            $DeviceDisplayName = $Device.DisplayName
            $AutopilotZTDID = ($Device.PhysicalIds | Select-String -Pattern '\[ZTDID\]:(.*)').Matches.Groups[1].Value
            $ReturnBodyTemp | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value "$DeviceDisplayName" -Force    # Add value for logging
            $ReturnBodyTemp | Add-Member -MemberType NoteProperty -Name "Target Group tag" -Value "$DeviceTargetGroupTag" -Force    # Add value for logging
            $ReturnBodyTemp | Add-Member -MemberType NoteProperty -Name "ZTDID" -Value "$AutopilotZTDID" -Force    # Add value for logging
            try {
                $DeviceGroupTag = ($Device.PhysicalIds | Select-String -Pattern '\[OrderId\]:(.*)').Matches.Groups[1].Value
                $ReturnBodyTemp | Add-Member -MemberType NoteProperty -Name "OrderId" -Value "$DeviceGroupTag" -Force    # Add value for logging
            }
            catch {
                Write-Error "$($DeviceDisplayName) is missing grouptag."
                $ReturnBodyTemp | Add-Member -MemberType NoteProperty -Name "OrderId" -Value "-" -Force    # Add value for logging
                $DeviceGroupTag = ""
            }

            # Check if current Group tag is Ok
            if ($DeviceTargetGroupTag -ne $DeviceGroupTag) {
                Write-Warning "$($DeviceDisplayName) has grouptag ""$($DeviceGroupTag)"" not matching target grouptag ""$($DeviceTargetGroupTag)"". Device will be updated."
                $ReturnBodyTemp | Add-Member -MemberType NoteProperty -Name "Action" -Value "Wrong Group tag" -Force    # Add value for logging
                
                # Update Autopilot device with new Group tag
                $params = @{
                    groupTag = $DeviceTargetGroupTag
                }
                try {
                    Update-MgBetaDeviceManagementWindowsAutopilotDeviceIdentityDeviceProperty -WindowsAutopilotDeviceIdentityId $AutopilotZTDID -BodyParameter $params
                    $ReturnBodyTemp | Add-Member -MemberType NoteProperty -Name "Status" -Value "Succeed" -Force    # Add value for logging
                    write-warning "Device $($CurrentDeviceName), Group tag set to $($DeviceTargetGroupTag)"              
                }
                catch {
                    $ReturnBodyTemp | Add-Member -MemberType NoteProperty -Name "Status" -Value "Failed" -Force    # Add value for logging
                    write-warning "Device $($CurrentDeviceName), Failed setting Group tag to $($DeviceTargetGroupTag)"              
                }

            }
            else {
                Write-Output "$($DeviceDisplayName) has grouptag ""$($DeviceGroupTag)"". No change required."
                $ReturnBodyTemp | Add-Member -MemberType NoteProperty -Name "Action" -Value "OK Group tag" -Force    # Add value for logging

            }

            #write output logs in JSON format
            $LogOutputMsg = $ReturnBodyTemp | ConvertTo-Json 
            Write-Output $LogOutputMsg
            
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