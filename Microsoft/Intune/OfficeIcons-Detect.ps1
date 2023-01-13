<#
  .NOTES
  ===========================================================================
   Created on:   	13.01.2023
   Created by:   	Simon Skotheimsvik
   Filename:     	OfficeIcons-Detect.ps1
   Instructions:    https://skotheimsvik.no
  ===========================================================================
  
  .DESCRIPTION
    This script will detect if Office icons are present
    Based on ideas from the Microsoft EMS Community on Discord and on Redit
#>

$StartMenuFolder = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
$Count = (Get-ChildItem $StartMenuFolder | ? Name -match "Word|Outlook|Powerpoint|Excel").count

if ($count -ge 4) { 
  "Installed" 
}

else {
  Exit 1
}