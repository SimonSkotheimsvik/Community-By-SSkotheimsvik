<#
  .NOTES
  ===========================================================================
   Created on:   	24.06.2022
   Created by:   	Simon Skotheimsvik
   Filename:     	Win11-SetDesktopTheme.ps1
   Info:          https://skotheimsvik.blogspot.com/
  ===========================================================================
  
  .DESCRIPTION
    This script downloads the themepack from Azure Blob Storage and activates the themepack for Windows11.
    The script can be assigned to devices in Microsoft Endpoint Manager.
    
  .EXAMPLE
    Win11-SetDesktopTheme.ps1 
#>

# Parameters for source and destination for the themepack file
$ThemepackSource = "https://XXXXXXXX.blob.core.windows.net/YYYYYYYYYYYYY/Win11-theme.deskthemepack"
$ThemepackDestinationFolder = "C:\temp\"
$WallpaperDestinationFile = "$ThemepackDestinationFolder\win11-corporate-theme.deskthemepack"

# Creates the destination folder on the target computer
md $ThemepackDestinationFolder -erroraction silentlycontinue

# Downloads the image file from the source location
Start-BitsTransfer -Source $ThemepackSource -Destination "$WallpaperDestinationFile"

# Assign the themepack
start-process -FilePath $WallpaperDestinationFile; timeout /t 3; taskkill /im "systemsettings.exe" /f