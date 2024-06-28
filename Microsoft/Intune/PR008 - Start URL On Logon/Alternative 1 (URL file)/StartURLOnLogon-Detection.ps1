<#
  .NOTES
   Created on:   	26.06.2024
   Created by:   	Simon Skotheimsvik
   Filename:     	StartURLOnLogon-Detection.ps1
   Info:          https://skotheimsvik.no
   Version:       1.0
  
  .DESCRIPTION
    This script will check if shortcut for URL is present in the startup folder.
    If file not exist or not equal, it will be downloaded from a webserver.
#>

# Define URLs and paths
$remoteFileUrl = "https://YOURPATH.blob.core.windows.net/intuneresources-public/SimonDoes.url"
$localFilePath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\SimonDoes.url"
$tempFilePath = "$($env:temp)\SimonDoes.url"

# Download the remote file to a temporary location
Invoke-WebRequest -Uri $remoteFileUrl -OutFile $tempFilePath

# Function to calculate file hash
function Get-FileHash {
  param ([string]$filePath)
  return (Get-FileHash -Algorithm SHA256 -Path $filePath).Hash
}

# Check if the local file exists
if (Test-Path $localFilePath) {
  # Calculate hashes for both files
  $localFileHash = Get-FileHash -Path $localFilePath
  $remoteFileHash = Get-FileHash -Path $tempFilePath
    
  # Compare the hashes
  if ($localFileHash -eq $remoteFileHash) {
    # Files are the same
    exit 0
  }
  else {
    # Files are different
    exit 1
  }
}
else {
  # Local file does not exist
  exit 1
}
