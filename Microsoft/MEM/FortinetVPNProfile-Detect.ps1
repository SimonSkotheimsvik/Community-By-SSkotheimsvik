<#
  .NOTES
  ===========================================================================
   Created on:   	27.06.2022
   Created by:   	Simon Skotheimsvik
   Filename:     	FortinetVPNProfile-Detect.ps1
   Instructions:    https://skotheimsvik.blogspot.com/
  ===========================================================================
  
  .DESCRIPTION
    This script will detect if VPN profile is present
    
#>

if((Test-Path -LiteralPath "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\Simons VPN") -ne $true) 
    {
    Write-Host "Not existing"
    Exit 1
    }
Else
    {
    Write-Host "OK"
    Exit 0
    }