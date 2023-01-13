<#
  .NOTES
  ===========================================================================
   Created on:   	27.06.2022
   Created by:   	Simon Skotheimsvik
   Filename:     	OfficeIcons-Remediation.ps1
   Instructions:    https://skotheimsvik.no
  ===========================================================================
  
  .DESCRIPTION
    This script will remediate the missing Office

#>

# Defining variables for the VPN connection

Start-Process "C:\Program Files\Microsoft Office 15\ClientX64\OfficeClickToRun.exe" -ArgumentList "scenario=Repair", "system=x64", "culture=en-us", "RepairType=QuickRepair", "DisplayLevel=False" -Wait 

$startMenu = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs"
$shortcutExists = (Get-ChildItem $startMenu -Include "Word.lnk" -Recurse -ErrorAction SilentlyContinue) -ne $null

if ($shortcutExists) {
  Write-Host "The Microsoft Word shortcut does exist in the start menu."
  $exitCode = 0
}
else {
  Write-Host "The Microsoft Word shortcut does not exist in the start menu."
  $exitCode = -1
} 

exit $exitCode