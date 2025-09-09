<#
.SYNOPSIS
    Script to create Azure AD License groups
.DESCRIPTION
    Script to create Azure AD License groups for available SKUs used for assigning licenses to users in the tenant.
.EXAMPLE
    
.NOTES
    Version:        1.1
    Author:         Simon Skotheimsvik
    Contact:        
    Version history:
    1.0 - (08.11.2022) Script released
    1.1 - (07.07.2023) Adding users with existing licenses to the groups
    1.2 - (13.02.2023) Convert to Microsoft Graph PowerShell SDK V2 module, Simon Skotheimsvik
    1.3 - (05.09.2025) Fix for UTF8 BOM issue when importing CSV from Microsoft, Simon Skotheimsvik

#>

#region functions
function RenameDisplayName {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$DisplayName
    )
    foreach ($Translation in $DisplayNameTranslations.GetEnumerator()) {
        $DisplayName = $DisplayName.Replace($Translation.Name, $Translation.Value)
    }
    $DisplayName
}# end function
#endregion functions

#region Variables
# Insert SKUs not manageable by groups: Get-MgBetaSubscribedSku | Where-Object { $_.SkuPartNumber -notin $SKUsNotToManage }
$SKUsNotToManage = @(
    "WINDOWS_STORE"
    "RMSBASIC"
    "MICROSOFT_REMOTE_ASSIST"
    "AAD_PREMIUM_P2_FACULTY"
    "Dynamics_365_Guides_vTrial"
    "FLOW_FREE"
    "WIN10_ENT_A5_FAC"
    "STREAM"
)

# Insert translations used to shorten group names
$DisplayNameTranslations = @{
    "Azure Active Directory"         = 'AAD'
    "Microsoft 365"                  = 'M365'
    "Office 365"                     = 'O365'
    "Enterprise Mobility + Security" = 'EMS'
    "Windows 365"                    = 'W365'
}

# Import Microsoft CSV file with friendly display name and SKU Partnumber, https://learn.microsoft.com/en-us/entra/identity/users/licensing-service-plan-reference
$licenseCsvURL = 'https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv'
$response = Invoke-WebRequest -Uri $licenseCsvURL

# Decode the byte array as UTF8 text
$csvText = [System.Text.Encoding]::UTF8.GetString($response.Content)

# Strip BOM if present
$csvText = $csvText -replace '^\uFEFF',''

# Now parse CSV
$csv = $csvText | ConvertFrom-Csv

# Build your hashtable
$skuHashTable = @{}
$csv | ForEach-Object {
    $skuHashTable[$_.String_Id] = @{
        "SkuId"         = $_.GUID
        "SkuPartNumber" = $_.String_Id
        "DisplayName"   = $_.Product_Display_Name
    }
}

#endregion Variables

#region connect
Connect-MgGraph -Scopes "Directory.Read.All", "Group.ReadWrite.All"
Import-Module Microsoft.Graph.Beta.Identity.DirectoryManagement
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Beta.Groups
#endregion connect

#region script 

# Gather all SKUs in Tenant
$SKUsToManage = Get-MgBetaSubscribedSku | Where-Object { $_.SkuPartNumber -notin $SKUsNotToManage }

# Create groups for SKUs in Tenant
foreach ($SKU in $SKUsToManage) {
    # Get friendly shortened GroupDisplayName
    $SKUpartno = $SKU.SkuPartNumber
    $GroupDisplayName = RenameDisplayName -DisplayName "AZ-LIC-$(($skuHashTable["$SKUpartno"]).DisplayName)"

    # Finds group, create it if not existing
    if ($Group = Get-MgBetaGroup -All | Where-Object { $_.DisplayName -like $GroupDisplayName }) {
        Write-Output """$GroupDisplayName"" exists"
    }
    else {
        Write-Output """$GroupDisplayName"" does not exist"
        $Group = New-MgBetaGroup -DisplayName $GroupDisplayName -Description "This group is used to assign $(($skuHashTable["$SKUpartno"]).DisplayName) licenses." -MailEnabled:$false -SecurityEnabled -MailNickName ($GroupDisplayName).Replace(" ", "") #-IsAssignableToRole:$true
    }

    # Add license to group
    $params = @{
        AddLicenses    = @(
            @{
                SkuId = $Sku.SkuId
            }
        )
        RemoveLicenses = @(
        )
    }
    Set-MgBetaGroupLicense -GroupId $Group.Id -BodyParameter $params

    #Get all users with the specified license
    Write-Output "Getting all users with the $(($skuHashTable["$SKUpartno"]).DisplayName) license"
    $users = Get-MgUser -All | Where-Object { $_.AssignedLicenses.SkuId -contains $($Sku.SkuId) }
    
    # Add users to the Azure security group
    Write-Output "Adding $($users.count) users to the $($GroupDisplayName) group"
    foreach ($user in $users) {
        $params = @{
            "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/{$($user.Id)}"
        }

        New-MgBetaGroupMemberByRef -GroupId $Group.Id -BodyParameter $params
    }
}
#endregion script 