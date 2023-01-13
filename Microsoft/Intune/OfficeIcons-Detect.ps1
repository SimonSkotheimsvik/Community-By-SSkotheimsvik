<#
  .NOTES
  ===========================================================================
   Created on:   	27.06.2022
   Created by:   	Simon Skotheimsvik
   Filename:     	OfficeIcons-Detect.ps1
   Instructions:    https://skotheimsvik.no
  ===========================================================================
  
  .DESCRIPTION
    This script will detect if Office icons are present

#>

$startMenu = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs"
$shortcutExists = (Get-ChildItem $startMenu -Include "Word.lnk" -Recurse -ErrorAction SilentlyContinue) -ne $null

if ($shortcutExists) {
  Write-Host "The Microsoft Word shortcut does exist in the start menu."
  Exit 0
}
else {
  Write-Host "The Microsoft Word shortcut does not exist in the start menu."
  Exit 1
} 
