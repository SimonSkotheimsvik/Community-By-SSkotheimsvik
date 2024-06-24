<#
.SYNOPSIS
    Script to check domains in a Microsoft 365 tenant.
.DESCRIPTION
    This script will check domains and DNS records for all domains in a Microsoft 365 tenant.
    MX, SPF, DKIM, DMARC, Autodiscover, Skype for Business, and other records will be checked. 
.EXAMPLE
    
.NOTES
    Author:         Simon Skotheimsvik
    Info:           https://skotheimsvik.no        
    Creation Date:  24.06.2024
    Version history:
                    1.0 - 24.06.2024 - Simon - Script released

#>

# Import the Microsoft Graph PowerShell module
Import-Module Microsoft.Graph.Identity.DirectoryManagement

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Domain.Read.All"

# Retrieve all domains from the Microsoft tenant
$domains = Get-MgDomain

# Function to check DNS records using Resolve-DnsName
function Get-DnsRecords {
    param (
        [string]$Domain,
        [string]$RecordType
    )

    try {
        $dnsRecords = Resolve-DnsName -Name $Domain -Type $RecordType -ErrorAction Stop
        return $dnsRecords
    }
    catch {
        return $null
    }
}

# Function to check DNS records for MX, SPF, DKIM, DMARC, Autodiscover, Skype for Business, and other records
function Check-DnsRecords {
    param (
        [string]$Domain
    )

    $result = [PSCustomObject]@{
        Domain                 = $Domain
        MX                     = $null
        SPF                    = $null
        DKIMSelector1          = $null
        DKIMSelector2          = $null
        DMARC                  = $null
        Autodiscover           = $null
        SIP                    = $null
        LyncDiscover           = $null
        SipTls                 = $null
        SipFederationTlsTcp    = $null
        EnterpriseRegistration = $null
        EnterpriseEnrollment   = $null
    }

    # Check MX records
    $mxRecords = Get-DnsRecords -Domain $Domain -RecordType "MX"
    if ($mxRecords) {
        $result.MX = $mxRecords | ForEach-Object { $_.Exchange -join "," }
    }

    # Check SPF record
    $spfRecords = Get-DnsRecords -Domain $Domain -RecordType "TXT"
    if ($spfRecords) {
        foreach ($record in $spfRecords) {
            foreach ($string in $record.Strings) {
                if ($string -match "^v=spf1") {
                    $result.SPF = $string
                    break
                }
            }
        }
    }

    # Check DKIM records
    $dkimSelector1 = "selector1._domainkey.$Domain"
    $dkimSelector2 = "selector2._domainkey.$Domain"

    $dkimRecord1 = Get-DnsRecords -Domain $dkimSelector1 -RecordType "CNAME"
    $dkimRecord2 = Get-DnsRecords -Domain $dkimSelector2 -RecordType "CNAME"

    if ($dkimRecord1) {
        $result.DKIMSelector1 = $dkimRecord1.NameHost
    }
    if ($dkimRecord2) {
        $result.DKIMSelector2 = $dkimRecord2.NameHost
    }

    # Check DMARC record
    $dmarcRecords = Get-DnsRecords -Domain "_dmarc.$Domain" -RecordType "TXT"
    if ($dmarcRecords) {
        foreach ($record in $dmarcRecords) {
            foreach ($string in $record.Strings) {
                if ($string -match "^v=DMARC1") {
                    $result.DMARC = $string
                    break
                }
            }
        }
    }

    # Check Autodiscover CNAME
    $autodiscoverRecord = Get-DnsRecords -Domain "autodiscover.$Domain" -RecordType "CNAME"
    if ($autodiscoverRecord) {
        $result.Autodiscover = $autodiscoverRecord.NameHost
    }

    # Check Skype for Business CNAMEs
    $SIPRecord = Get-DnsRecords -Domain "sip.$Domain" -RecordType "CNAME"
    if ($SIPRecord) {
        $result.SIP = $SIPRecord.NameHost
    }

    $LyncDiscoverRecord = Get-DnsRecords -Domain "lyncdiscover.$Domain" -RecordType "CNAME"
    if ($LyncDiscoverRecord) {
        $result.LyncDiscover = $LyncDiscoverRecord.NameHost
    }

    # Check Skype for Business SRV records
    $SipTlsRecord = Get-DnsRecords -Domain "_sip._tls.$Domain" -RecordType "SRV"
    if ($SipTlsRecord) {
        $result.SipTls = $SipTlsRecord | ForEach-Object { $_.NameTarget }
    }

    $SipFederationTlsTcpRecord = Get-DnsRecords -Domain "_sipfederationtls._tcp.$Domain" -RecordType "SRV"
    if ($SipFederationTlsTcpRecord) {
        $result.SipFederationTlsTcp = $SipFederationTlsTcpRecord | ForEach-Object { $_.NameTarget }
    }

    # Check Enterprise Registration and Enrollment CNAMEs
    $EnterpriseRegistrationRecord = Get-DnsRecords -Domain "enterpriseregistration.$Domain" -RecordType "CNAME"
    if ($EnterpriseRegistrationRecord) {
        $result.EnterpriseRegistration = $EnterpriseRegistrationRecord.NameHost
    }

    $EnterpriseEnrollmentRecord = Get-DnsRecords -Domain "enterpriseenrollment.$Domain" -RecordType "CNAME"
    if ($EnterpriseEnrollmentRecord) {
        $result.EnterpriseEnrollment = $EnterpriseEnrollmentRecord.NameHost
    }

    return $result
}

# Array to hold results
$results = @()

# Check DNS records for each domain and include additional parameters
foreach ($domain in $domains) {
    Write-Host "Checking DNS records for domain: $($domain.Id)"
    $dnsResult = Check-DnsRecords -Domain $domain.Id

    $result = [PSCustomObject]@{
        Domain                           = $domain.Id
        AuthenticationType               = $domain.AuthenticationType
        IsAdminManaged                   = $domain.IsAdminManaged
        IsDefault                        = $domain.IsDefault
        IsInitial                        = $domain.IsInitial
        IsRoot                           = $domain.IsRoot
        IsVerified                       = $domain.IsVerified
        PasswordNotificationWindowInDays = $domain.PasswordNotificationWindowInDays
        PasswordValidityPeriodInDays     = $domain.PasswordValidityPeriodInDays
        SupportedServices                = $domain.SupportedServices
        MX                               = $dnsResult.MX
        SPF                              = $dnsResult.SPF
        DKIMSelector1                    = $dnsResult.DKIMSelector1
        DKIMSelector2                    = $dnsResult.DKIMSelector2
        DMARC                            = $dnsResult.DMARC
        Autodiscover                     = $dnsResult.Autodiscover
        SIP                              = $dnsResult.SIP
        LyncDiscover                     = $dnsResult.LyncDiscover
        SipTls                           = $dnsResult.SipTls -join ","
        SipFederationTlsTcp              = $dnsResult.SipFederationTlsTcp -join ","
        EnterpriseRegistration           = $dnsResult.EnterpriseRegistration
        EnterpriseEnrollment             = $dnsResult.EnterpriseEnrollment
    }

    $results += $result
    Write-Host "----------------------------------------"
}

# Sort results alphabetically by Domain
$results = $results | Sort-Object Domain

# Output results to CSV
$results | Export-Csv -Path "DomainDnsReport.csv" -NoTypeInformation

# Convert results to JSON for display
# $results | ConvertTo-Json

# Disconnect from Microsoft Graph
Disconnect-MgGraph

Write-Host "DNS report exported to DomainDnsReport.csv"
