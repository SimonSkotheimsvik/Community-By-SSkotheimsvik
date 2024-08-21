<#
  .NOTES
   Created on:   21.08.2024
   Created by:   Simon Skotheimsvik
   Filename:     Public360RegistrySettings-Remediation.ps1
   Version:      1.0 - Initial version, Simon Skotheimsvik
  
  .DESCRIPTION
   This script checks if the registry settings for the 360 Addin and other settings for the current user are set correctly.
#>

$RegContent = @"
RegKeyPath,Key,Value,Type
"HKCU:\Software\Software Innovation\360\Addin","DefaultSite","nih.public360online.com","String"
"HKCU:\Software\Software Innovation\360\Addin\Sites\nih.public360online.com","Web Application Url","https://nih.public360online.com","String"
"HKCU:\Software\Software Innovation\360\Addin\Sites\nih.public360online.com","LCIDS","[LCIDS]","String"
"HKCU:\Software\Software Innovation\360\Addin\Sites\nih.public360online.com","Is Upgrade From 4.0",0,"DWord"
"HKCU:\Software\Wow6432Node\Software Innovation\360\Addin","DefaultSite","nih.public360online.com","String"
"HKCU:\Software\Wow6432Node\Software Innovation\360\Addin\Sites\nih.public360online.com","Web Application Url","https://nih.public360online.com","String"
"HKCU:\Software\Wow6432Node\Software Innovation\360\Addin\Sites\nih.public360online.com","LCIDS",1044,"DWord"
"HKCU:\Software\Wow6432Node\Software Innovation\360\Addin\Sites\nih.public360online.com","Is Upgrade From 4.0",0,"DWord"
"HKCU:\SOFTWARE\Policies\Google\Chrome\URLWhitelist","1","si-pdx://*","String"
"HKCU:\SOFTWARE\Policies\Google\Chrome\URLAllowlist","1","si-pdx://*","String"
"HKCU:\SOFTWARE\Policies\Microsoft\Edge\URLAllowlist","1","si-pdx://*","String"
"HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\nih.public360online.com","https",2,"DWord"
"HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\360online-ne.accesscontrol.windows.net","https",2,"DWord"
"HKCU:\Software\Wow6432Node\Microsoft\Office\Outlook\Resiliency\DoNotDisableAddinList","SI.Outlook.Sidebar.Container",1,"DWord"
"HKCU:\Software\Microsoft\Office\16.0\Outlook\Resiliency\DoNotDisableAddinList","SI.Outlook.Sidebar.Container",1,"DWord"
"HKCU:\Software\Microsoft\Office\15.0\Outlook\Resiliency\DoNotDisableAddinList","SI.Outlook.Sidebar.Container",1,"DWord"
"HKCU:\SOFTWARE\Wow6432Node\Microsoft\Office\Outlook\Addins\SI.Outlook.Sidebar.Container","LoadBehavior",3,"DWord"
"HKCU:\SOFTWARE\Wow6432Node\Microsoft\Office\Outlook\Addins\SI.Outlook.Sidebar.Container","Manifest","C:\Program Files (x86)\Tieto\360\binc\SI.Outlook.Sidebar.Container.vsto|vstolocal","String"
"HKCU:\SOFTWARE\Wow6432Node\Microsoft\Office\Outlook\Addins\SI.Outlook.Sidebar.Container","FriendlyName","SI.Outlook.Sidebar.Container","String"
"HKCU:\SOFTWARE\Wow6432Node\Microsoft\Office\Outlook\Addins\SI.Outlook.Sidebar.Container","Description","SI.Outlook.Sidebar.Container","String"
"HKCU:\SOFTWARE\Microsoft\Office\Outlook\Addins\SI.Outlook.Sidebar.Container","LoadBehavior",3,"DWord"
"HKCU:\SOFTWARE\Microsoft\Office\Outlook\Addins\SI.Outlook.Sidebar.Container","Manifest","C:\Program Files (x86)\Tieto\360\binc\SI.Outlook.Sidebar.Container.vsto|vstolocal","String"
"HKCU:\SOFTWARE\Microsoft\Office\Outlook\Addins\SI.Outlook.Sidebar.Container","FriendlyName","SI.Outlook.Sidebar.Container","String"
"HKCU:\SOFTWARE\Microsoft\Office\Outlook\Addins\SI.Outlook.Sidebar.Container","Description","SI.Outlook.Sidebar.Container","String"
"HKCU:\Software\Microsoft\Office\16.0\Word\Security","VBAWarnings",2,"DWord"
"HKCU:\Software\Microsoft\Office\16.0\Word\Security\Trusted Locations","AllowNetworkLocations",1,"DWord"
"HKCU:\Software\Microsoft\Office\16.0\Word\Security\Trusted Locations\360_nih.public360online.com","Path","https://nih.public360online.com/360templates/","String"
"HKCU:\Software\Microsoft\Office\16.0\Word\Security\Trusted Locations\360_nih.public360online.com","AllowSubfolders",1,"DWord"
"HKCU:\Software\Microsoft\Office\16.0\Word\Security\Trusted Locations\nih.public360online.com","Path","https://nih.public360online.com/biz/v2-pbr/docprod/templates/","String"
"HKCU:\Software\Microsoft\Office\16.0\Word\Security\Trusted Locations\nih.public360online.com","AllowSubfolders",1,"DWord"
"HKCU:\Software\Microsoft\Office\15.0\Word\Security","VBAWarnings",2,"DWord"
"HKCU:\Software\Microsoft\Office\15.0\Word\Security\Trusted Locations","AllowNetworkLocations",1,"DWord"
"HKCU:\Software\Microsoft\Office\15.0\Word\Security\Trusted Locations\360_nih.public360online.com","Path","https://nih.public360online.com/360templates/","String"
"@


$RegData = $RegContent | ConvertFrom-Csv -delimiter ","

foreach ($Reg in $RegData) {

    IF (!(Test-Path ($Reg.RegKeyPath))) {
        Write-Host ($Reg.RegKeyPath) " does not exist. Will be created."
        New-Item -Path $($Reg.RegKeyPath) -Force | Out-Null
    }
    
    IF ((Get-ItemProperty -Path $Reg.RegKeyPath -Name $Reg.Key -ErrorAction SilentlyContinue) -eq $null) {
        Write-Host "$($Reg.Key) does not exist. Will be created."
        New-ItemProperty -Path $($Reg.RegKeyPath) -Name $($Reg.Key) -Value $($Reg.Value) -PropertyType $($Reg.Type) -Force
    }
    
    $ExistingValue = (Get-Item -Path $($Reg.RegKeyPath)).GetValue($($Reg.Key))
    if ($ExistingValue -ne $($Reg.Value)) {
        Write-Host "$($Reg.Key) not correct value. Will be set."
        Set-ItemProperty -Path $($Reg.RegKeyPath) -Name $($Reg.Key) -Value $($Reg.Value) -Force
    }
    else {
        Write-Host "$($Reg.Key) is correct"
    }
}

Exit 0
