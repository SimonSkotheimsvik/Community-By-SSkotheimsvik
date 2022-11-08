<#
.SYNOPSIS
  Script to create Azure AD License groups.
.DESCRIPTION
    Script to create Azure AD License groups for available SKUs used for assigning licenses to users in the tenant.
    The script has a table of SKUs not managed by groups, and a table of translations to apply common abbreviations.
.EXAMPLE
    
.NOTES
    Version:        1.0
    Author:         Simon Skotheimsvik
    Contact:        
    Creation Date:  08.11.2022
    Updated:              03.11.2022
    Version history:
    1.0 - (08.11.2022) Script released

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

# Insert SKUs not manageable by groups
$SKUsNotToManage = @(
    "WINDOWS_STORE"
    "RMSBASIC"
)

# Insert translations used to shorten group names
$DisplayNameTranslations = @{
    "Azure Active Directory" = 'AAD'
    "Microsoft 365"          = 'M365'
}

# Import Microsoft CSV file with friendly display name and SKU Partnumber
$licenseCsvURL = 'https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv'
 
$skuHashTable = @{}
(Invoke-WebRequest -Uri $licenseCsvURL).ToString() | ConvertFrom-Csv | ForEach-Object {
    $skuHashTable[$_.String_Id] = @{
        "SkuId"         = $_.GUID
        "SkuPartNumber" = $_.String_Id
        "DisplayName"   = $_.Product_Display_Name
    }
}

#endregion Variables

#region connect
Select-MgProfile beta
Connect-MgGraph -Scopes "Directory.Read.All", "Group.ReadWrite.All" -ForceRefresh
Import-Module Microsoft.Graph.Groups
#endregion connect

#region script 

# Gather all SKUs in Tenant
$SKUsToManage = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -notin $SKUsNotToManage }

# Create groups for SKUs in Tenant
foreach ($SKU in $SKUsToManage) {
    # Get friendly shortened GroupDisplayName
    $SKUpartno = $SKU.SkuPartNumber
    $GroupDisplayName = RenameDisplayName -DisplayName "AZ-LIC-$(($skuHashTable["$SKUpartno"]).DisplayName)"

    # Finds group, create it if not existing
    if ($Group = Get-MgGroup | Where-Object { $_.DisplayName -like $GroupDisplayName }) {
        Write-Output """$GroupDisplayName"" exists"
    }
    else {
        Write-Output """$GroupDisplayName"" does not exist"
        $Group = New-MgGroup -DisplayName $GroupDisplayName -Description "This group is used to assign $(($skuHashTable["$SKUpartno"]).DisplayName) licenses." -MailEnabled:$false -SecurityEnabled -MailNickName ($GroupDisplayName).Replace(" ", "") #-IsAssignableToRole:$true
    }

    # Add license to group
    $params = @{
        AddLicenses = @(
            @{
                SkuId = $Sku.SkuId
            }
        )
        RemoveLicenses = @(
        )
    }
    Set-MgGroupLicense -GroupId $Group.Id -BodyParameter $params
}
#endregion script 