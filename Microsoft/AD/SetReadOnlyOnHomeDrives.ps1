<#
.SYNOPSIS
This script retrieves home directories of users from Active Directory, lists unique servers and paths, counts users per path, verifies path existence, and modifies access rights on the home directories.

.DESCRIPTION
This script retrieves home directories of users from Active Directory, lists unique servers and paths, counts users per path, verifies path existence, and modifies access rights on the home directories.
There are several sections in the script that can be uncommented to run specific parts of the script. The script is designed to be run in a controlled environment where the user has the necessary permissions to modify access rights on the home directories.

.NOTES
Author:  Simon Skotheimsvik
Version:
        1.0.0 - 2024-11-06 - Initial release, Simon Skotheimsvik
#>

#region Variables
$OU = "OU=users,DC=domain,DC=com"
$domain = "Your Domain"

# Path to log CSV
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$JsonLogPath = "C:\temp\homedrive-removereadrights-log_$timestamp.json"
$TxtLogPath = "C:\temp\homedrive-removereadrights-log_$timestamp.txt"
$log = @()  # Initialize an array to hold log entries
#endregion Variables


#region Manual testing
<#### List all homefolder paths
Get-ADUser -Filter * -SearchBase $OU -Properties homeDirectory | ForEach-Object {
    $_.homeDirectory
} | out-gridview
#>

<##### List all unique servers
$servers = Get-ADUser -Filter * -SearchBase $OU -Properties homeDirectory | ForEach-Object {
    # Extract the server name from the UNC path
    if ($_.homeDirectory -match "^\\\\([^\\]+)\\") {
        $matches[1] # This is the server name from the UNC path (e.g., \\ServerName\Share)
    }
}

$uniqueServers = $servers | Sort-Object -Unique
$uniqueServers
#>

<#
##### List all unique homefolder paths
$serverPaths = Get-ADUser -Filter * -SearchBase $OU -Properties homeDirectory | ForEach-Object {
    # Remove the last segment (username) from the home directory path
    if ($_.homeDirectory -match "^(.*)\\[^\\]+$") {
        # This captures everything up to the last backslash
        $matches[1]  # This results in the path without the username
    }
}

$uniqueServerPaths = $serverPaths | Sort-Object -Unique
$uniqueServerPaths
#>


<#### Count users adressing each unique homefolder path and verify if the path is alive
$UsersInOu = ($serverPaths = Get-ADUser -Filter * -SearchBase $OU -Properties homeDirectory).count
$serverPaths = Get-ADUser -Filter * -SearchBase $OU -Properties homeDirectory | ForEach-Object {
    # Remove the last segment (username) from the home directory path
    if ($_.homeDirectory -match "^(.*)\\[^\\]+$") {
        # This captures everything up to the last backslash
        $matches[1]  # This results in the path without the username
    }
}

# Get unique server paths
$uniqueServerPaths = $serverPaths | Sort-Object -Unique

# Initialize an array to store custom objects for each path
$serverPathUserCountArray = @()

# Loop through each unique server path and count users, and check if the path is alive
foreach ($path in $uniqueServerPaths) {
    # Count the number of users for this path
    $userCount = ($serverPaths | Where-Object { $_ -eq $path }).Count
    
    # Check if the folder path exists (is alive)
    $isPathAlive = Test-Path $path

    # Create a custom object to store path, user count, and alive status
    $serverPathUserCountArray += [PSCustomObject]@{
        Path        = $path
        UserCount   = $userCount
        IsAlive     = $isPathAlive
    }
}

# Display the result
$serverPathUserCountArray
$totalUsersWithHomeDir = ($serverPathUserCountArray | Measure-Object -Property UserCount -Sum).Sum
Write-Host "$($totalUsersWithHomeDir) of $($UsersInOu) users in $($OU) have a homedir"
#>


<#### List all users homedrives and driveletters
Get-ADUser -Filter * -SearchBase $OU -Properties UserPrincipalName, homeDirectory, homeDrive | ForEach-Object {
    $userPrincipalName = $_.UserPrincipalName
    $homeDirectory = $_.homeDirectory
    $driveLetter = $_.homeDrive

    # Create a custom object for each user
    [PSCustomObject]@{
        UserPrincipalName = $userPrincipalName
        HomeDirectory     = $homeDirectory
        DriveLetter       = $driveLetter
    }
 } | Sort-Object -Property HomeDirectory -Descending | out-gridview
#>
#endregion Manual testing

#region Change rights on homedrives
#### Traversing each user and modify rights on the homedrive folders
# $users = Get-ADUser -Filter {Name -eq "simons"} -SearchBase $OU -Properties homeDirectory
$users = Get-ADUser -Filter * -SearchBase $OU -Properties homeDirectory

foreach ($user in $users) {
    $homeDir = $user.HomeDirectory
    if (Test-Path -Path $homeDir) {
        Write-Host "Homedir for $($user.Name) found at $($homeDir)"
        
        # Get current ACL before change
        $ACL = Get-Acl -Path $homeDir
        
        # Get the user identity
        $userIdentity = New-Object System.Security.Principal.NTAccount($domain, $user.SamAccountName)

        # Get current ACL for the user on Home directory
        $aclUserAccessBefore = $ACL.Access | Where-Object { $_.IdentityReference -eq $userIdentity }

        # Extract ACL details into a cleaner format
        $permissionsBefore = $aclUserAccessBefore | Select-Object -Property IdentityReference, FileSystemRights, AccessControlType, IsInherited | ForEach-Object {
            [PSCustomObject]@{
                IdentityReference = $_.IdentityReference.ToString()
                FileSystemRights = $_.FileSystemRights
                AccessControlType = $_.AccessControlType
                IsInherited = $_.IsInherited
            }
        }

        # Define the new ACL
        #$ACL.setAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($userIdentity, "Read", "ContainerInherit,ObjectInherit", "none", "allow")))
        $ACL.setAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($userIdentity, "Read, ReadAndExecute, ListDirectory", "ContainerInherit,ObjectInherit", "none", "allow")))

        # Set the new ACL
#        Set-Acl -Path $homeDir $ACL

        # Get current ACL for the user on Home directory after the change
        $ACLnew = Get-Acl -Path $homeDir
        $aclUserAccessAfter = $ACLnew.Access | Where-Object { $_.IdentityReference -eq $userIdentity }

        # Extract ACL details after the change
        $permissionsAfter = $aclUserAccessAfter | Select-Object -Property IdentityReference, FileSystemRights, AccessControlType, IsInherited | ForEach-Object {
            [PSCustomObject]@{
                IdentityReference = $_.IdentityReference.ToString()
                FileSystemRights = $_.FileSystemRights
                AccessControlType = $_.AccessControlType
                IsInherited = $_.IsInherited
            }
        }

        # Log the details to the array
        $logEntry = [PSCustomObject]@{
            UserSamAccountName = $user.SamAccountName
            HomeDirectory = $homeDir
            Status = "ACL updated"
            ACLBefore = $permissionsBefore
            ACLAfter = $permissionsAfter
        }
        
        $log += $logEntry  # Add entry to log array
        
    } else {
        Write-Host "Homedir for $($user.Name) not found at $($homeDir)"

        # Log the details to the array
        $logEntry = [PSCustomObject]@{
            UserSamAccountName = $user.SamAccountName
            HomeDirectory = $homeDir
            Status = "Directory not found"
            ACLBefore = $null
            ACLAfter = $null
        }
        
        $log += $logEntry  # Add entry to log array

    }        
}

# Convert log array to JSON and export it to the specified path
$log | ConvertTo-Json -Depth 7 | Out-File -FilePath $JsonLogPath
$log | Out-String | Set-Content -Path $TxtLogPath

#endregion Change rights on homedrives