<#
.SYNOPSIS
    Remediation to uninstall N-Able client

.DESCRIPTION
    This script searches for the N-Able client in the registry and uninstalls it if found.

.NOTES
    Author: Simon Skotheimsvik
    Version: 1.0.0 - 2025-08-12, Simon Skotheimsvik, Initial version

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
$name = "Patch Management Service Controller"
$publisher = "N-able"
$logFile = Join-Path $imeLogFolder "uninstall_log_$($name).log"

# Define registry paths to search
$registryPaths = @(
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
)

foreach ($path in $registryPaths) {
    Get-ChildItem -Path $path | ForEach-Object {
        $displayName = (Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue).DisplayName
        $publisherName = (Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue).Publisher
        $QuietUninstallString = (Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue).QuietUninstallString
        if ($displayName -eq $name -and $publisherName -eq $publisher) {
            Write-Log "Found key: $($_.Name)"
            # Extract the GUID from the registry key name
            if ($_.Name -match '{[A-F0-9\-]+}') {
                $guid = $matches[0]
                Write-Log "Starting uninstall of $($name) from $($publisherName) with guid $($guid) using $($QuietUninstallString)."
                Write-Output "Starting uninstall of $($name) from $($publisherName) with guid $($guid) using $($QuietUninstallString)."
#                Start-Process -FilePath "msiexec.exe" -ArgumentList "/X$($guid) /qn" -Wait
                # Hardcoding the uninstall string found in registry
                Start-Process "C:\Program Files (x86)\MspPlatform\PME\unins000.exe" -ArgumentList "/SILENT" -Wait
                Write-Output "$($name) from $($publisherName) with guid $($guid) uninstalled using $($QuietUninstallString)."
                Exit 1

            } else {
                Write-Log "No GUID found in key: $($_.Name)"
                Write-Output "No GUID found for $($name) from $($publisherName). Cannot uninstall."
                Exit 0
            }
        }
    }
}
