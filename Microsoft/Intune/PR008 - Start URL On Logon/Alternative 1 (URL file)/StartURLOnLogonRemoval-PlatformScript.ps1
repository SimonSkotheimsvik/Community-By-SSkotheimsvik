<#
  .NOTES
   Created on:    26.06.2024
   Created by:    Simon Skotheimsvik
   Filename:      StartURLOnLogonRemoval-PlatformScript.ps1
   Info:          https://skotheimsvik.no 
   Version:       1.0
  
  .DESCRIPTION
    This Platform script removes alt 1 using the URL file
#>


# clean out alternative 1 using URL file, if it exists
$path = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\SimonDoes.url"; if (Test-Path $path) { Remove-Item $path }

Exit 0
