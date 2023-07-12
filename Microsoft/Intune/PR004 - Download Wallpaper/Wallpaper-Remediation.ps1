<#
  .NOTES
  ===========================================================================
   Created on:   	12.07.2023
   Created by:   	Simon Skotheimsvik
   Filename:     	Wallpaper-Remediation.ps1
   Info:          https://skotheimsvik.no
  ===========================================================================
  
  .DESCRIPTION
    This script detects if wallpaper from Azure Storage exists locally
    The script can be assigned as Remediation script in Microsoft Intune
    The downloaded wallpaper can be configured in Intune Settings catalog  
        Wallpaper Style: (User) Stretch
        Wallpaper Name: (User)  C:\Windows\web\wallpaper\wallpaper.jpg  
        Desktop Wallpaper (Use) Enabled
#>

$imageURL = "https://cloudlimits.blob.core.windows.net/intuneresources-public/cloudlimits.jpg"
$imagePATH = "C:\Windows\web\wallpaper\wallpaper.jpg"

if (!(Test-Path -Path $imagePATH -PathType Leaf)) {
    Write-Host "Wallpaper missing on computer"
    try {
        Invoke-WebRequest -Uri $imageURL -OutFile $imagePATH -TimeoutSec 10 -UseBasicParsing:$true -ErrorAction SilentlyContinue
        Exit 0
    }
    catch {
        Write-Host "An error occurred:"
        Write-Host $_
        Exit 1    
    }
}
else
{
  Write-Host "Wallpaper exists on computer"
  Exit 0
}