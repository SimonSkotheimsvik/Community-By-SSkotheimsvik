<#
  .NOTES
  ===========================================================================
   Created on:   	06.06.2024
   Created by:   	Simon Skotheimsvik
   Filename:     	WPS006 - ShowFileExtensionsWindowsExplorer.ps1
   Info:          https://skotheimsvik.no
  ===========================================================================
  
  .DESCRIPTION
    This script enables file extensions in Windows Explorer for Windows10 and Windows 11
    The setting is found in "View - Show - File name extensions"
    The script is assigned as platform script to users in MicrosoftIntune.  
#>

#region - Get information about signed in user. 
# Routine inspired by Rudy Ooms: https://call4cloud.nl/2020/03/how-to-deploy-hkcu-changes-while-blocking-powershell/#part4

# Get information of current user
$currentUser = (Get-Process -IncludeUserName -Name explorer | Select-Object -First 1 | Select-Object -ExpandProperty UserName).Split("\")[1] 

$Data = $currentUser
$Keys = GCI "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\" -Recurse
Foreach ($Key in $Keys) {
  IF (($key.GetValueNames() | % { $key.GetValue($_) }) -match "\b$CurrentUser\b" ) { $sid = $key }
}

# Add SID of current user to a variable
$sid = $sid.pschildname

New-PSDrive HKU Registry HKEY_USERS | out-null
#endregion

#region RegistryContent

$RegistryContent = @"
RegKeyPath,Key,Value,Type
"HKU:\$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced","HideFileExt","0", "DWord"
"@

$RegistryC = $RegistryContent | ConvertFrom-Csv -delimiter ","


foreach ($Content in $RegistryC) {

  IF (!(Test-Path ($Content.RegKeyPath))) {
      Write-Host ($Content.RegKeyPath) " does not exist. Will be created."
      New-Item -Path $RegKeyPath -Force | Out-Null
  }
  IF ((Get-ItemProperty -Path $Content.RegKeyPath -Name $Content.Key -ErrorAction SilentlyContinue) -eq $null) {
      Write Host $($Content.Key) " does not exist. Will be created."
      New-ItemProperty -Path $($Content.RegKeyPath) -Name $($Content.Key) -Value $($Content.Value) -PropertyType $($Content.Type) -Force
  }
  
  $ExistingValue = (Get-Item -Path $($Content.RegKeyPath)).GetValue($($Content.Key))
  if ($ExistingValue -ne $($Content.Value)) {
      Write-Host $($Content.Key) " not correct value. Will be set."
      Set-ItemProperty -Path $($Content.RegKeyPath) -Name $($Content.Key) -Value $($Content.Value) -Force
  }
  else {
      Write-Host $($Content.Key) " is correct"
  }
}


# Clears the error log from powershell before exiting
$error.clear()

#endregion