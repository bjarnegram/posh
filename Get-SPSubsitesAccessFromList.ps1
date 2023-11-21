# ================================
#
# Script to get subsites from Site Collections
# Included members of <site> Owners group
#
# ================================

# Requires -RunAsAdministrator

<#
.SYNOPSIS
    Get list of subsites with owners from Site Collections

.DESCRIPTION
    Get-SPSubsitesWithOwners is a function that gets a list
    of subsites with members of Site Owners group
    from one or more Site Collections in a CSV file.

    It's running in the context of the current user, and will
    only get information about Site Collections and
    Sub Sites that the current user has access to.

    NB!
    It depends on posh/include-functions.ps1 

.PARAMETER Path
    Path to Csv-File containing Site Collections
    Csv-file must have following structure:
        [Site Name;
        Site Url;
        Owner;
        Expiration Date;
        Site Status;
        Provisioning Status;
        External Collaboration;
        Confidentiality;
        Organization;
        Site Audience;
        Template;
        Gdpr;
        Sensitive Gdpr;
        Business Area Level;
        Business Division Level]

.NOTES
    Author:  Bjarne L. Gram
    Email:   bjarne.l.gram@no.abb.com
    Twitter: @bjarnegram
#>

[CmdletBinding()]
param
(
    [Parameter(Mandatory)]
    [string]$Path
)

# Parameters
if (-not (Test-Path $Path)) {
    Write-Prompt
    Write-Important "The file $($Path) does not exist."
    Stop-Transcript
    Exit
}

# Get location of input file to store output file and log
$CsvLocation = Split-Path -Path $Path

# Logging
$dateStamp = Get-Date -Format yyyy-MM-dd-HH-mm-ss
$logFile = "Get-SPSubsitesWithOwners-$dateStamp.log"
$logFile = Join-Path $CsvLocation $logFile
Start-Transcript -Path $logFile 

# Include Functions
. "$PSScriptRoot\include-functions.ps1"

#Debug true - used by include-functions.ps1
$isDebug = $true

#Write a header
Write-Header "Get list of subsites with owners from Site Collections in CSV-file"

# Set file paths
$CsvInputFilePath = $Path
$CsvOutputFilePath = "Get-SPSubsitesWithOwners-$dateStamp.csv"
$CsvOutputFilePath = Join-Path $CsvLocation $CsvOutputFilePath
Write-Prompt "Using Input CSV-file:         $($CsvInputFilePath)"
Write-Prompt "Writing Output to CSV-file:   $($CsvOutputFilePath)"

# Import CSV-file
$InputSiteCollections = Import-Csv -Path $CsvInputFilePath -Delimiter ';' 

# Add properties not already in file 
$MissingMembers = @{
    'Site Collection Admins'  = ''
    'Sub Site Name'           = ''
    'Sub Site Url'            = ''
    'Associated Owners Group' = ''
    'Created By'              = ''
}
$InputSiteCollections | Add-Member -NotePropertyMembers $MissingMembers

# Set properties in relevant order
$OutputSiteCollections = Select-Object -InputObject $InputSiteCollections -Property 'Site Name',
'Site Url',
'Site Collection Admins',
'Created By',
'Sub Site Name',
'Sub Site Url',
'Associated Owners Group',
Owner,
'Expiration Date',
'External Collaboration',
Confidentiality,
Organization,
Template,
Gdpr,
'Sensitive Gdpr',
'Business Area Level',
'Business Division Level'

# Save CSV setup to output file
$OutputSiteCollections | Export-Csv -Path $CsvOutputFilePath -Delimiter ';'

# Write list of Site Collections in file
Write-Prompt "CSV-file contains $($InputSiteCollections.Count) Site Collections"
$InputSiteCollections | Format-Table -Property 'Site Name', 'Site Url', Owner

# Loop through Site Collections in file
foreach ($SiteCollection in $InputSiteCollections) {
    if ($SiteCollection) {
        
        $SiteCollectionUrl = $SiteCollection.'Site Url'
        $SiteOwner = $SiteCollection.Owner

        Write-DoubleLine
        Write-Host
        Write-Prompt "Site Collection Name:                 $($SiteCollection.'Site Name')"
        Write-Prompt "Site Collection Url:                  $($SiteCollectionUrl)"
        Write-Prompt "Current Site Collection Owner in CSV: $($SiteOwner)"
        
        # Open Site Collection and find sub sites
        Connect-PnPOnline -Url $SiteCollectionUrl -Interactive
    
        # Get Site Collection Admins
        try {
            $SCAdmins = Get-PnPSiteCollectionAdmin -ErrorAction SilentlyContinue
        }
        catch {
            $SCAdmins = $null
            Write-DebugInfo "No SC Admins or error connecting..."
        }
        Write-Host

        if ($SCAdmins) {
            Write-DebugInfo "There are $($SCAdmins.Count) Site Collection Administrators in SharePoint:"
    
            $SiteCollectionAdminsString = "["
    
            foreach ($SCAdmin in $SCAdmins) {
                Write-DebugInfo "- $($SCAdmin.Title) <$($SCAdmin.Email)>"
                $SiteCollectionAdminsString += $($SCAdmin.Email)
                $SiteCollectionAdminsString += ","
            }
    
            $SiteCollectionAdminsString += "]"
            $SiteCollection.'Site Collection Admins' = $SiteCollectionAdminsString
            $SiteCollectionAdminsString = ""
    

            Write-Host
        }
        else {
            $SiteCollection.'Site Collection Admins' = 'N/A'
        }

        # Get all sub sites from Site Collection
        # Only get Author field if it exists
        try {
            $SubSites = Get-PnPSubWeb -Recurse -IncludeRootWeb -Includes "Author"
        }
        catch {
            try {
                $SubSites = Get-PnPSubWeb -Recurse -IncludeRootWeb 
            }
            catch {
                # NO SUBSITES IN CURRENT SITE COLLECTION
                $SubSites = $null
                $SiteCollection.'Sub Site Name' = "No Access"
            }
        }
        
        # Add row to CSV Output file
        $SiteCollection | Export-Csv -Path $CsvOutputFilePath -Append -Delimiter ";"
    
    }

}
Write-DoubleLine
Write-Done
Stop-Transcript