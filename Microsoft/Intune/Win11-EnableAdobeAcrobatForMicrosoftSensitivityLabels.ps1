<#
  .NOTES
  ===========================================================================
   Created on:   	20.12.2022
   Created by:   	Simon Skotheimsvik
   Filename:     	Win11-EnableAdobeAcrobatForMicrosoftSensitivityLabels.ps1
   Info:          https://skotheimsvik.no
  ===========================================================================
  
  .DESCRIPTION
    This script sets registry information in Windows10 and Windows11
    to enable Adobe Acrobat to work with Microsoft Sensitivity labels
    defined in Microsoft Purview as defined by Nikki Chapple in her blog
    https://nikkichapple.com/how-to-use-sensitivity-labels-with-your-pdf-files/
    
    The script can be assigned to users in Microsoft Endpoint Manager.
    
  .EXAMPLE
    Win11-EnableAdobeAcrobatForMicrosoftSensitivityLabels.ps1 
#>

#region - Get information about signed in user. 
# Routine inspired by Rudy Ooms: https://call4cloud.nl/2020/03/how-to-deploy-hkcu-changes-while-blocking-powershell/#part4

$currentUser = (Get-Process -IncludeUserName -Name explorer | Select-Object -First 1 | Select-Object -ExpandProperty UserName).Split("\")[1] 

$Data = $currentUser
$Keys = GCI "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\" -Recurse
Foreach ($Key in $Keys) {
  IF (($key.GetValueNames() | % { $key.GetValue($_) }) -match "\b$CurrentUser\b" ) { $sid = $key }
}

$sid = $sid.pschildname

New-PSDrive HKU Registry HKEY_USERS | out-null

#endregion


#region Variables for sensitivity labels in Adobe Acrobat
$RegKeyPath1 = "HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown"
$RegKeyPath2 = "HKU:\$sid\SOFTWARE\Adobe\Adobe Acrobat\DC\MicrosoftAIP"

$bMIPCheckPolicyOnDocSave = "bMIPCheckPolicyOnDocSave"
$bMIPCheckPolicyOnDocSaveValue = 1

$bMIPLabelling = "bMIPLabelling"
$bMIPLabellingValue = 1

$bShowDMB = "bShowDMB"
$bShowDMBValue = 1
#endregion

#region Implementation of registry settings
IF (!(Test-Path $RegKeyPath1)) {
  New-Item -Path $RegKeyPath1 -Force | Out-Null
}

IF (!(Test-Path $RegKeyPath2)) {
  New-Item -Path $RegKeyPath2 -Force | Out-Null
}

New-ItemProperty -Path $RegKeyPath1 -Name $bMIPCheckPolicyOnDocSave -Value $bMIPCheckPolicyOnDocSaveValue -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $RegKeyPath1 -Name $bMIPLabelling -Value $bMIPLabellingValue -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $RegKeyPath2 -Name $bShowDMB -Value $bShowDMBValue -PropertyType DWord -Force | Out-Null

# Clears the error log from powershell before exiting
$error.clear()

#endregion