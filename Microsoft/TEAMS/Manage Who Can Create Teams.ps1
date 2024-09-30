# https://learn.microsoft.com/en-us/microsoft-365/solutions/manage-creation-of-groups?view=o365-worldwide

# Import the required modules
Import-Module Microsoft.Graph.Beta.Identity.DirectoryManagement
Import-Module Microsoft.Graph.Beta.Groups

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Directory.ReadWrite.All", "Group.Read.All"


# Check configuration
(Get-MgBetaDirectorySetting).Values

# Get information about the group allowed to create teams
$group = Get-MgBetaGroup -Id 


