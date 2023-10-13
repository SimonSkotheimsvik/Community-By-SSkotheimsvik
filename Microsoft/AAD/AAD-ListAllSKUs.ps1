<#
    .SYNOPSIS
    Created on:     13.10.2023
    Last update:    13.10.2023
    Created by:     CloudWay, Simon Skotheimsvik
    Info:           
    
    .DESCRIPTION
    Script to list numbers related to license usages in tenant
#>

# Install required module
Install-Module -Name Microsoft.Graph

# Import the module
Import-Module Microsoft.Graph.Identity.DirectoryManagement

# Authenticate and set Graph endpoint
Connect-MgGraph -Scopes Directory.Read.All

# Retrieve the friendly SKUnames from the provided URL
$url = "http://bit.ly/SKUFriendlyNames"
$friendlyNames = Invoke-RestMethod -Uri $url -UseBasicParsing | Convertfrom-Csv -Delimiter ';'

# Get all SKUs
$skus = Get-MgSubscribedSku

# Display SKUs with product names and available units
$skus | ForEach-Object {
    $sku = $_
    $productName = ($friendlyNames | Where-Object { $_.LicenseSKUID -eq $sku.SkuId }).ProductName

    [PSCustomObject]@{
        ProductName = $productName
        SkuPartNumber = $sku.SkuPartNumber
        SkuId = $sku.SkuId
        ConsumedUnits = $sku.ConsumedUnits
        AvailableUnits = $sku.PrepaidUnits.Enabled
    }
} | Format-Table