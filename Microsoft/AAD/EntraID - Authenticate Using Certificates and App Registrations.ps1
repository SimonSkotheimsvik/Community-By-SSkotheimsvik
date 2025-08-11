<#
.SYNOPSIS
    This script holds the code for setting up and using self-signed certificates for authentication with Microsoft Entra ID (Azure AD) and Microsoft Graph API.

.DESCRIPTION
    The script holds two main sections:
    1. Setting up self-signed certificates, including creating, exporting, and importing them.
    2. Authenticating to Microsoft Graph using the created certificates and executing a sample workload.

    The script is designed to be run in a PowerShell environment with the necessary permissions and modules installed, such as the Microsoft Graph PowerShell SDK.
    It is important to replace placeholder values like `$Password`, `$tenantID`, and `$clientID` with actual values before running the script.
    The script is structured to be modular, allowing for easy adjustments and reuse in different environments or scenarios.
    The script is intended to be run manually as an example of how to authenticate using certificates in PowerShell.

.NOTES
    Author: Simon Skotheimsvik
    Version: 1.0.0 - 2025-08-04, Simon Skotheimsvik, Initial version

    license: This script is provided as-is, without warranty of any kind. Use at your own risk.
    You may modify and redistribute this script as long as you retain this notice in the code.
#>


######################################
### SET UP THE CERTIFICATES        ###
######################################

#region Variables
$CertificateName = "GraphAutomationCert"
$CertificatePath = "C:\Temp\GraphAutomationCert"
$Password = "YourStrongPassword"
$CertificateType = "LocalMachine"  # Options: "CurrentUser" or "LocalMachine"
#endregion

#region Create Self-Signed Certificate on the server
$LifeTimeMonths = "18"
$cert = New-SelfSignedCertificate -Subject "CN=$CertificateName" -CertStoreLocation "Cert:\$CertificateType\My" -KeyExportPolicy Exportable -KeySpec Signature -NotAfter (Get-Date).AddMonths($LifeTimeMonths)
#endregion

#region Export Self-Signed Certificate for the Entra ID App
Write-Host "Exporting certificate to: $CertificatePath.cer" -ForegroundColor Green
Export-Certificate -Cert $cert -FilePath "$CertificatePath.cer"
#endregion

#region Backup/Export Self-Signed Certificate with Private Key for use on other computer
Write-Host "Exporting certificate to: $CertificatePath.pfx" -ForegroundColor Green
$pwd = ConvertTo-SecureString -String $Password -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "$CertificatePath.pfx" -Password $pwd
#endregion

#region Restore/Import Self-Signed Certificate
$certPath = "$CertificatePath.pfx"
$certPassword = ConvertTo-SecureString -String $Password -Force -AsPlainText

$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$cert.Import($certPath, $certPassword, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
#endregion


######################################
### USE THE CERTIFICATES           ###
######################################

#region Authenticate Using Certificate
# Variables
$tenantId = "11111111-2222-3333-4444-555555555555"
$clientId = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
$CertThumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -like "*CN=GraphAutomationMachineCert*" }).Thumbprint

# Load the certificate from the store
$cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $CertThumbprint }

# Connect to Microsoft Graph
Write-Host "Connecting to Graph using certificate with thumbprint: $($cert.Thumbprint)" -ForegroundColor Yellow
Connect-MgGraph -ClientId $clientId -TenantId $tenantId -Certificate $cert -NoWelcome
#endregion

#region PS Workload
Write-Host "Executing Microsoft Graph workload..." -ForegroundColor Green
Get-MgUser -Top 5
#endregion