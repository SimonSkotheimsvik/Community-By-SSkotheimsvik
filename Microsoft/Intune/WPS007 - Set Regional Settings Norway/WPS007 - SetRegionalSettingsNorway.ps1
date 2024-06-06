<#
  .NOTES
  ===========================================================================
   Created on:   	06.06.2024
   Created by:   	Simon Skotheimsvik
   Filename:     	WPS007 - SetRegionalSettingsNorway.ps1
   Info:          https://skotheimsvik.no
  ===========================================================================
  
  .DESCRIPTION
    This script sets regional settings to Norwegian for Windows10 and Windows 11
    The script is assigned as platform script to users in MicrosoftIntune, running as the logged on credentials.  
#>


# Set system locale to Norwegian (Bokmål, Norway)
Set-WinSystemLocale nb-NO

# Set user locale to Norwegian (Bokmål, Norway)
Set-WinUserLanguageList nb-NO -Force

# Set the input method to Norwegian
Set-WinUILanguageOverride nb-NO

# Set the location to Norway
Set-WinHomeLocation -GeoId 177

# Set formats to Norwegian (Bokmål, Norway)
Set-Culture -CultureInfo "nb-NO"