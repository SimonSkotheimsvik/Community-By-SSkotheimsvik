<#
.SYNOPSIS
    Add QR code authentication method for a user using Microsoft Graph API

.DESCRIPTION
    This script demonstrates how to add a software OATH token (QR code) authentication method 
    for a user in Entra ID (Azure AD) using Microsoft Graph REST API.
    The script will return the secret key and generate a QR code that can be scanned with 
    an authenticator app.

    Source: https://learn.microsoft.com/en-us/entra/identity/authentication/how-to-authentication-qr-code#add-qr-code-authentication-method-for-a-user-in-microsoft-graph-api

.PARAMETER UserPrincipalName
    The UPN of the user to add the authentication method to

.PARAMETER SaveQRCode
    Save the QR code as an image file (PNG or JPG)

.PARAMETER OutputPath
    The path where the QR code image should be saved. If not specified, saves to current directory

.PARAMETER ImageFormat
    The image format for the QR code (PNG or JPG). Default is PNG

.PARAMETER Force
    Automatically delete existing QR code authentication method without prompting

.EXAMPLE
    .\EntraID-Add-QRCodeAuthenticationMethod.ps1 -UserPrincipalName "user@contoso.com"

.EXAMPLE
    .\EntraID-Add-QRCodeAuthenticationMethod.ps1 -UserPrincipalName "user@contoso.com" -SaveQRCode -ImageFormat PNG

.EXAMPLE
    .\EntraID-Add-QRCodeAuthenticationMethod.ps1 -UserPrincipalName "user@contoso.com" -SaveQRCode -OutputPath "C:\QRCodes" -ImageFormat JPG

.NOTES
    Author: Simon Skotheimsvik, CloudWay
    Date: November 28, 2025
    Requires: Microsoft.Graph PowerShell SDK
    Required Permission: UserAuthenticationMethod.ReadWrite.All

    Version:
        1.0.0 - Initial release, Simon Skotheimsvik   
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserPrincipalName,
    
    [Parameter(Mandatory = $false)]
    [switch]$SaveQRCode,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = $PWD,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('PNG', 'JPG')]
    [string]$ImageFormat = 'PNG',
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Required modules
$requiredModule = "Microsoft.Graph.Authentication"
if (-not (Get-Module -ListAvailable -Name $requiredModule)) {
    Write-Host "Installing required module: $requiredModule" -ForegroundColor Yellow
    Install-Module -Name $requiredModule -Scope CurrentUser -Force
}

# Connect to Microsoft Graph with required scopes
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "UserAuthenticationMethod.ReadWrite.All", "User.Read.All" -NoWelcome

# Get the user ID
Write-Host "Looking up user: $UserPrincipalName" -ForegroundColor Cyan
try {
    $user = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$UserPrincipalName"
    $userId = $user.id
    Write-Host "Found user: $($user.displayName) (ID: $userId)" -ForegroundColor Green
}
catch {
    Write-Error "Failed to find user: $_"
    Disconnect-MgGraph
    exit
}

# Check for existing QR Code authentication method
Write-Host "`nChecking for existing QR Code authentication methods..." -ForegroundColor Cyan
$existingQRCodeUri = "https://graph.microsoft.com/beta/users/$userId/authentication/qrCodePinMethod"

try {
    $existingQRCode = Invoke-MgGraphRequest -Method GET -Uri $existingQRCodeUri -ErrorAction SilentlyContinue
    
    if ($existingQRCode) {
        Write-Host "Found existing QR Code authentication method" -ForegroundColor Yellow
        Write-Host "  Created: $($existingQRCode.standardQRCode.startDateTime)" -ForegroundColor White
        Write-Host "  Expires: $($existingQRCode.standardQRCode.expireDateTime)" -ForegroundColor White
        
        # Determine if we should delete
        $shouldDelete = $false
        
        if ($Force) {
            Write-Host "`n-Force parameter specified, automatically deleting existing QR code..." -ForegroundColor Yellow
            $shouldDelete = $true
        }
        else {
            # Prompt to delete existing method
            $response = Read-Host "`nAn active QR code already exists. Delete it and create a new one? (Y/N)"
            $shouldDelete = ($response -eq 'Y' -or $response -eq 'y')
        }
        
        if ($shouldDelete) {
            Write-Host "Deleting existing QR Code authentication method..." -ForegroundColor Cyan
            try {
                Invoke-MgGraphRequest -Method DELETE -Uri $existingQRCodeUri
                Write-Host "✓ Existing QR Code deleted successfully" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to delete existing QR Code: $_"
                Disconnect-MgGraph
                exit
            }
        }
        else {
            Write-Host "Operation cancelled by user." -ForegroundColor Yellow
            Disconnect-MgGraph
            exit
        }
    }
}
catch {
    # No existing QR code found (404 error is expected), continue
    Write-Host "No existing QR Code found" -ForegroundColor Green
}

# Add QR Code authentication method
Write-Host "`nAdding QR Code authentication method..." -ForegroundColor Cyan

# Generate a random 8-digit PIN for the QR code (minimum requirement)
$pin = Get-Random -Minimum 10000000 -Maximum 99999999
Write-Host "Generated PIN: $pin" -ForegroundColor Yellow

# Set QR code validity period (30 days from now)
$startDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$expireDateTime = (Get-Date).AddDays(30).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Construct the request body
$body = @{
    standardQRCode = @{
        expireDateTime = $expireDateTime
        startDateTime = $startDateTime
    }
    pin = @{
        code = $pin.ToString()
    }
} | ConvertTo-Json

# PUT request to add the QR code authentication method
$uri = "https://graph.microsoft.com/beta/users/$userId/authentication/qrCodePinMethod"

try {
    $response = Invoke-MgGraphRequest -Method PUT -Uri $uri -Body $body -ContentType "application/json"
    
    Write-Host "`n============================================" -ForegroundColor Green
    Write-Host "QR Code Authentication Method Added Successfully!" -ForegroundColor Green
    Write-Host "============================================`n" -ForegroundColor Green
    
    # Display the PIN
    Write-Host "PIN Code: " -ForegroundColor Yellow -NoNewline
    Write-Host $pin -ForegroundColor Green
    
    # Display validity period
    Write-Host "`nValidity Period:" -ForegroundColor Yellow
    Write-Host "  Start:  $startDateTime" -ForegroundColor White
    Write-Host "  Expire: $expireDateTime" -ForegroundColor White
    
    # Extract QR code data from response
    $qrCodeData = $null
    $qrCodeSvg = $null
    
    if ($response.standardQRCode) {
        # Check for rawContent (base64 encoded string)
        if ($response.standardQRCode.image -and $response.standardQRCode.image.rawContent) {
            $qrCodeData = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($response.standardQRCode.image.rawContent))
        }
        # Check for binaryValue (SVG content)
        if ($response.standardQRCode.image -and $response.standardQRCode.image.binaryValue) {
            $qrCodeSvg = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($response.standardQRCode.image.binaryValue))
        }
    }
    
    # Save QR code as image file if requested
    if ($SaveQRCode) {
        if ($qrCodeSvg) {
            try {
                # Ensure output directory exists
                if (-not (Test-Path $OutputPath)) {
                    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
                }
                
                # Create filename with timestamp and user
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $sanitizedUser = $UserPrincipalName -replace '[^a-zA-Z0-9]', '_'
                
                # Save as SVG first
                $svgFileName = "QRCode_${sanitizedUser}_${timestamp}.svg"
                $svgFilePath = Join-Path $OutputPath $svgFileName
                $qrCodeSvg | Out-File -FilePath $svgFilePath -Encoding UTF8
                
                Write-Host "`n============================================" -ForegroundColor Cyan
                Write-Host "QR Code Image Saved" -ForegroundColor Cyan
                Write-Host "============================================" -ForegroundColor Cyan
                Write-Host "SVG File:  " -ForegroundColor Yellow -NoNewline
                Write-Host $svgFilePath -ForegroundColor White
                
                # If PNG or JPG requested, also create via online converter
                if ($ImageFormat -ne 'SVG' -and $qrCodeData) {
                    try {
                        $imageFileName = "QRCode_${sanitizedUser}_${timestamp}.${ImageFormat.ToLower()}"
                        $imageFilePath = Join-Path $OutputPath $imageFileName
                        
                        Write-Host "`nConverting to $ImageFormat..." -ForegroundColor Cyan
                        $format = if ($ImageFormat -eq 'JPG') { 'jpeg' } else { 'png' }
                        $downloadUrl = "https://api.qrserver.com/v1/create-qr-code/?size=500x500&format=$format&data=" + [System.Web.HttpUtility]::UrlEncode($qrCodeData)
                        
                        Invoke-WebRequest -Uri $downloadUrl -OutFile $imageFilePath
                        
                        Write-Host "$ImageFormat File: " -ForegroundColor Yellow -NoNewline
                        Write-Host $imageFilePath -ForegroundColor White
                        Write-Host "Size:      " -ForegroundColor Yellow -NoNewline
                        Write-Host "500x500 pixels" -ForegroundColor White
                    }
                    catch {
                        Write-Warning "Could not create $ImageFormat file, but SVG is available: $($_.Exception.Message)"
                    }
                }
                
                Write-Host "============================================" -ForegroundColor Cyan
            }
            catch {
                Write-Warning "Failed to save QR code image: $($_.Exception.Message)"
            }
        }
        else {
            Write-Warning "QR code image data not available in response."
        }
    }
    
    # Display QR Code information
    if ($qrCodeData) {
        Write-Host "`nQR Code Data: " -ForegroundColor Yellow
        Write-Host $qrCodeData -ForegroundColor White
        
        # Generate QR Code URL for visualization
        $qrCodeUrl = "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=" + [System.Web.HttpUtility]::UrlEncode($qrCodeData)
        
        Write-Host "`nQR Code URL (open in browser to view): " -ForegroundColor Yellow
        Write-Host $qrCodeUrl -ForegroundColor White
        
        # Copy QR URL to clipboard
        try {
            Set-Clipboard -Value $qrCodeUrl
            Write-Host "`n✓ QR Code URL copied to clipboard!" -ForegroundColor Green
        }
        catch {
            Write-Host "`nNote: Could not copy to clipboard automatically." -ForegroundColor Yellow
        }
    }
    
    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "Instructions:" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "1. Share the PIN code with the user: $pin" -ForegroundColor White
    Write-Host "2. User should scan the QR code with their device" -ForegroundColor White
    Write-Host "3. User enters the PIN when prompted" -ForegroundColor White
    Write-Host "4. QR code is valid until: $expireDateTime" -ForegroundColor White
    
    # Return the full response object only if not saving QR code (verbose mode)
    if (-not $SaveQRCode) {
        Write-Host "`n============================================" -ForegroundColor Cyan
        Write-Host "Full Response Details:" -ForegroundColor Cyan
        Write-Host "============================================" -ForegroundColor Cyan
        $response | ConvertTo-Json -Depth 5
    }
    
}
catch {
    Write-Error "Failed to add authentication method: $_"
    Write-Host "`nError Details:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# Disconnect from Microsoft Graph
Write-Host "`nDisconnecting from Microsoft Graph..." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null

Write-Host "`nScript completed." -ForegroundColor Green
