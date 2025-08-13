<#
.SYNOPSIS
    Remediation to uninstall N-Able client

.DESCRIPTION
    This script searches for the N-Able client in the registry and uninstalls it if found.

.NOTES
    Author: Simon Skotheimsvik
    Version: 1.0.0 - 2025-08-12, Simon Skotheimsvik, Initial version
    Version: 1.0.1 - 2025-08-12, Simon Skotheimsvik, Changed application to uninstall. Extended logging.
    Version: 1.0.2 - 2025-08-12, Simon Skotheimsvik, Fixed error handling and exit codes.
    Version: 1.0.3 - 2025-08-12, Simon Skotheimsvik, Calling msiexec directly to ensure exit code is returned.

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

# Define registry paths to search
$registryPaths = @(
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
)

foreach ($path in $registryPaths) {
    Get-ChildItem -Path $path -ErrorAction SilentlyContinue | ForEach-Object {
        $itemProps = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
        if ($itemProps.DisplayName -eq $name -and $itemProps.Publisher -eq $publisher) {
            Write-Log "Found key: $($_.Name)"

            if ($_.Name -match '{[A-F0-9\-]+}') {
                $guid = $matches[0]
                Write-Log "Attempting uninstall: $name ($guid) from $publisher."

                # Run uninstall
                # Start-Process -FilePath "msiexec.exe" -ArgumentList "/X$guid /qn" -Wait
                & "msiexec.exe" /X$guid /qn
                $exitCode = $LASTEXITCODE

                if ($exitCode -eq 0) {
                    Write-Log "Uninstall successful for $name ($guid)."
                    Write-Output "$name uninstalled successfully."
                    $success = $true
                } else {
                    Write-Log "Uninstall FAILED for $name ($guid). MSI exit code: $exitCode"
                    Write-Output "Failed to uninstall $name. MSI exit code: $exitCode"
                    Exit 1
                }
            }
            else {
                Write-Log "No GUID found in registry key: $($_.Name)"
                Write-Output "Cannot uninstall $name - GUID not found."
                # Exit 1
            }
        }
    }
}

if (-not $success) {
    Write-Log "Application not found. Nothing to uninstall."
    Write-Output "$name not found. Nothing to do."
}

Write-Log "=== Script finished at $(Get-Date -Format 'yyyy-MM-dd HH:mm') ==="
Exit 0