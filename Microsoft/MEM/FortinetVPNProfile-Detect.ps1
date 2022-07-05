<#
  .NOTES
  ===========================================================================
   Created on:   	27.06.2022
   Created by:   	Simon Skotheimsvik
   Filename:     	FortinetVPNProfile-Detect.ps1
   Instructions:    https://skotheimsvik.blogspot.com/2022/07/fortinet-vpn-profile-distribution-with.html
  ===========================================================================
  
  .DESCRIPTION
    This script will detect if VPN profile is present

#>

# Defining variables for the VPN connection
$VPNName = "Simons VPN"

if((Test-Path -LiteralPath "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\$VPNName") -ne $true) 
    {
    Write-Host "Not existing"
    Exit 1
    }
Else
    {
    Write-Host "OK"
    Exit 0
    }