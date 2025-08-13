<#
.SYNOPSIS
    Remediation to uninstall N-Able client

.DESCRIPTION
    This script searches for the N-Able client in the registry and uninstalls it if found.

.NOTES
    Author: Simon Skotheimsvik
    Version: 1.0.0 - 2025-08-12, Simon Skotheimsvik, Initial version
    Version: 1.0.1 - 2025-08-12, Simon Skotheimsvik, Changed application to uninstall.
    Version: 1.0.2 - 2025-08-12, Simon Skotheimsvik, Fixed error handling and exit codes.

    license: This script is provided as-is, without warranty of any kind. Use at your own risk.
    You may modify and redistribute this script as long as you retain this notice in the code.
#>


# Define log file path in the IME extension logs folder
$imeLogFolder = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
if (-not (Test-Path $imeLogFolder)) {
    New-Item -Path $imeLogFolder -ItemType Directory -Force | Out-Null
}

# Function to log messages
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp $Message"
}

# variables
$name = "Windows Agent"
$publisher = "N-able Technologies"
$logFile = Join-Path $imeLogFolder "uninstall_log_$($name).log"
$datetime = Get-Date -Format "yyyy-MM-dd HH:mm"
$found = $false

# Define registry paths to search
$registryPaths = @(
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
)

foreach ($path in $registryPaths) {
    Get-ChildItem -Path $path | ForEach-Object {
        $displayName = (Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue).DisplayName
        $publisherName = (Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue).Publisher
        if ($displayName -eq $name -and $publisherName -eq $publisher) {
            $found = $true
            Write-Log "Found key: $($_.Name)"
            # Extract the GUID from the registry key name
            if ($_.Name -match '{[A-F0-9\-]+}') {
                $guid = $matches[0]
                Write-Log "Found MSI with GUID: $guid"
                Write-Output "Found $($name) from $($publisherName) with guid $($guid), $($datetime)"
                Exit 1

            } else {
                Write-Log "No GUID found in key: $($_.Name)"
                Write-Output "No GUID found for $($name) from $($publisherName), $($datetime)."
                Exit 0
            }
        }
    }
}

if (-not $found) {
    Write-Log "No registry key found for $name from $publisher."
    Write-Output "No $($name) from $($publisher) found, no remediation required, $($datetime)."
    Exit 0
}