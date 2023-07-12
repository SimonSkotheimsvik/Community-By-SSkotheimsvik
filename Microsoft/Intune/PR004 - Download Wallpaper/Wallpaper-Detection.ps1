<#
  .NOTES
  ===========================================================================
   Created on:   	11.07.2023
   Created by:   	Simon Skotheimsvik
   Filename:     	Wallpaper-Detection.ps1
   Info:          https://skotheimsvik.no
  ===========================================================================
  
  .DESCRIPTION
    This script detects if wallpaper from Azure Storage exists locally
    The script can be assigned as Detection script in Microsoft Intune    
#>

$imageURL = "https://cloudlimits.blob.core.windows.net/intuneresources-public/cloudlimits.jpg"
$imagePATH = "C:\Windows\web\wallpaper\wallpaper.jpg"

if (!(Test-Path -Path $imagePATH -PathType Leaf)) {
  Write-Host "Wallpaper missing on computer"
  Exit 1  #File missing
}
else
{
  Write-Host "Wallpaper exists on computer"
  Exit 0
}