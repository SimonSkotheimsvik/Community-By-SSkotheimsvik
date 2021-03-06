<#
  .NOTES
  ===========================================================================
   Created on:   	27.06.2022
   Created by:   	Simon Skotheimsvik
   Filename:     	FortinetVPNProfile-Remediation.ps1
   Instructions:    https://skotheimsvik.blogspot.com/2022/07/fortinet-vpn-profile-distribution-with.html
  ===========================================================================
  
  .DESCRIPTION
    This script will create a VPN profile

#>

# Defining variables for the VPN connection
$VPNName = "Simons VPN"
$Server = "vpn.skotheimsvik.no:443"

# Install VPN Profiles
New-Item "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\$VPNName" -force -ea SilentlyContinue;
New-ItemProperty -LiteralPath "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\$VPNName" -Name 'Description' -Value $VPNName -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\$VPNName" -Name 'Server' -Value $Server -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\$VPNName" -Name 'promptusername' -Value 1 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\$VPNName" -Name 'promptcertificate' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\$VPNName" -Name 'ServerCert' -Value '1' -PropertyType String -Force -ea SilentlyContinue;

if ((Test-Path -LiteralPath "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\$VPNName") -ne $true) {
    $exitCode = -1
}
else {
    $exitCode = 0
}

exit $exitCode