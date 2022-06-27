<#
  .NOTES
  ===========================================================================
   Created on:   	23.06.2022
   Created by:   	Simon Skotheimsvik
   Filename:     	Win11-AddPrintersFromPrintserver.ps1
   Instructions:    https://skotheimsvik.blogspot.com/
  ===========================================================================
  
  .DESCRIPTION
    This script will connect printers from a printserver to an Azure AD joined
    Windows11 device with user signed in with a hybrid identity.
    
  .EXAMPLE
    Win11-AddPrintersFromPrintserver.ps1 
#>

# $Printers = (Get-Printer -ComputerName PrintServer).Name
# $Printers = (Get-Printer -ComputerName PrintServer | Where-Object {$_.Name -like "Simon*"}).Name
$printers = @(
    '\\printserver\printer1'
    '\\printserver\printer2'
    '\\printserver\plotter1'
    '\\printserver\plotter2'
)

ForEach ($printer in $printers) {
    $IsInstalled = [bool](Get-Printer | Where-Object {$_.Name -eq $printer})
    if (-not $IsInstalled) {
        Add-Printer -ConnectionName $printer -ErrorAction Stop
    }
}
