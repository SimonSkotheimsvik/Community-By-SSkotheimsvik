<#
  .NOTES
  ===========================================================================
   Created on:   	27.06.2022
   Created by:   	Simon Skotheimsvik
   Filename:     	FortinetVPNProfile-Remediation.ps1
   Instructions:    https://skotheimsvik.blogspot.com/
  ===========================================================================
  
  .DESCRIPTION
    This script will create a VPN profile
    
#>

# Install VPN Profiles
New-Item "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\Simons VPN" -force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\Simons VPN' -Name 'Description' -Value 'Simons VPN' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\Simons VPN' -Name 'Server' -Value 'vpn.simon.com:443' -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\Simons VPN' -Name 'promptusername' -Value 1 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\Simons VPN' -Name 'promptcertificate' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\Simons VPN' -Name 'ServerCert' -Value '1' -PropertyType String -Force -ea SilentlyContinue;

if((Test-Path -LiteralPath "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\Simons VPN") -ne $true) {
    $exitCode = -1
}
else {
    $exitCode = 0
}

exit $exitCode