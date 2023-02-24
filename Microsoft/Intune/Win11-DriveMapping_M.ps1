# Get users that are logged in
$Sessions = Get-WmiObject -Class win32_process | Where-Object {$_.name -eq "explorer.exe"}

# Get SID of users
$sid = $Sessions.GetOwnerSid().sid
$user=$Sessions.GetOwner().User

# Drivemapping variables 
$DriveLetter = "M"
$DrivePath = "\\server.skotheimsvik.no\users\$user"
$Path = "REGISTRY::HKEY_USERS\$sid\Network"

# Delete existing drivemapping
Remove-Item -Path "REGISTRY::HKEY_USERS\$sid\Network\$DriveLetter" -Force -ErrorAction SilentlyContinue | Out-Null

# Add new drivemapping
New-Item -Path $Path -Name $DriveLetter -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $Path\$DriveLetter\ -Name ConnectFlags -PropertyType DWORD -Value 0 -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $Path\$DriveLetter\ -Name ConnectionType -PropertyType DWORD -Value 1  -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $Path\$DriveLetter\ -Name DeferFlags -PropertyType DWORD -Value 4 -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $Path\$DriveLetter\ -Name ProviderFlags -PropertyType DWORD -Value 1 -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $Path\$DriveLetter\ -Name ProviderName -PropertyType String -Value "Microsoft Windows Network" -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $Path\$DriveLetter\ -Name ProviderType -PropertyType DWORD -Value 131072 -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $Path\$DriveLetter\ -Name RemotePath -PropertyType String -Value "$DrivePath" -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $Path\$DriveLetter\ -Name UserName -PropertyType String  -ErrorAction SilentlyContinue | Out-Null