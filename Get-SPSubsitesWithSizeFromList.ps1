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

    Column 'List Item Count' shows sum of items in all lists in site.
    Column 'List Item Size' shows size of items in all lists in MB.
    Column 'List Versions Size' shows sum of items including versions in MB.

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
    Email:   bjarne@microgram.no
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
$CsvOutputFilePath = "Get-SPSubsitesWithSizeFromList-$dateStamp.csv"
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
    'List Item Count'         = ''
    'List Size'               = ''
    'List Versions Size'      = ''
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
'List Item Count',
'List Size',
'List Versions Size',
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

                    
        # Sum Items i MB
        try {$StorageMetrics = Get-PnPFolderStorageMetric}
        catch {$StorageMetrics = $null}
        if($StorageMetrics){
            $SumItemsCount = $StorageMetrics.TotalFileCount
            $SumItemsSize =     $StorageMetrics.TotalFileStreamSize
            $SumVersionsSize =  $StorageMetrics.TotalSize

            $SiteCollection.'List Item Count' = $SumItemsCount
            $SiteCollection.'List Size' = $SumItemsSize
            $SiteCollection.'List Versions Size' = $SumVersionsSize

            Write-Prompt "Sub Site List Items Count:     $(Format-Bytes($SumItemsCount))"
            Write-Prompt "Sub Site List Size:            $(Format-Bytes($SumItemsSize))"
            Write-Prompt "Sub Site List Versions Size:   $(Format-Bytes($SumVersionsSize))"
            Write-Host            
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
                $SiteCollection.'Sub Site Name' = "N/A"
            }
        }
        
        # Add row to CSV Output file
        # $SiteCollection | Export-Csv -Path $CsvOutputFilePath -Append -Delimiter ";"

        if ($SubSites) {
            # Write out info about sub sites in Site Collection
            Write-Prompt "Site Collection $($SiteCollection.'Site Name') contains $($SubSites.Count) Sub Sites"
            Write-Host
            $SubSites | Format-Table -Property Title, ServerRelativeUrl
    
            # Loop through sub sites
            foreach ($SubSite in $SubSites) {
                
                # Filter away On-Prem sites and Apps
                if ($SubSite.Url -like 'https://abb.sharepoint.com/*') {

                    # Copy of SC Object for addition
                    $SCCopy = $SiteCollection.PSObject.Copy()
    
                    $SCCopy.'Sub Site Name' = $SubSite.Title
                    $SCCopy.'Sub Site Url' = $SubSite.Url
                    if ($SubSite.Author) {
                        $SCCopy.'Created By' = $SubSite.Author.Email
                    }
                    else {
                        $SCCopy.'Created By' = ""
                    }

                    Write-Line
                    Write-Host
                    Write-Prompt "Sub Site Title:                $($SubSite.Title)"
                    Write-Prompt "Sub Site Url:                  $($SubSite.Url)"
                    Write-Prompt "Sub Site Created By:           $($SubSite.Author.Email)"
                    Write-Host
        
                    # Connect to Sub Site
                    Connect-PnPOnline -Url $SubSite.Url -Interactive

                    # Sum Items i MB
                    $StorageMetrics = Get-PnPFolderStorageMetric
                    $SumItemsCount = $StorageMetrics.TotalFileCount
                    $SumItemsSize =     $StorageMetrics.TotalFileStreamSize
                    $SumVersionsSize =  $StorageMetrics.TotalSize

                    $SCCopy.'List Item Count' = $SumItemsCount
                    $SCCopy.'List Size' = $SumItemsSize
                    $SCCopy.'List Versions Size' = $SumVersionsSize

                    Write-Prompt "Sub Site List Items Count:     $(Format-Bytes($SumItemsCount))"
                    Write-Prompt "Sub Site List Size:            $(Format-Bytes($SumItemsSize))"
                    Write-Prompt "Sub Site List Versions Size:   $(Format-Bytes($SumVersionsSize))"
                    Write-Host

                    # Get Owners and loop through
                    $OwnerGroup = Get-PnPGroup -AssociatedOwnerGroup -ErrorAction SilentlyContinue
                    if ($OwnerGroup) {
                        $SCCopy.'Associated Owners Group' = $OwnerGroup.Title
                        $OwnerMembers = Get-PnPGroupMember -Group $OwnerGroup -ErrorAction SilentlyContinue
                        Write-DebugInfo "Associated Owner Group is $($OwnerGroup.Title):"
                        if ($OwnerMembers.Count -gt 0) {
                            $OwnerString += "["
                            foreach ($OwnerMember in $OwnerMembers) {
                                if ($OwnerMember.PrincipalType -eq "User" -and $OwnerMember.Title -ne "System Account") {
                                    Write-DebugInfo "- $($OwnerMember.Title) <$($OwnerMember.Email)>"
                                    $OwnerString += $($OwnerMember.Email)
                                    $OwnerString += ","
                                }
                            }
                            $OwnerString = $OwnerString.Substring(0, ($OwnerString.Length - 1))
                            $OwnerString += "]"
                            
                            $SCCopy.Owner = $OwnerString
                            $OwnerString = ""
                            Write-Host
                        }
                    }
        
                    # Output Site data to file
                    $SCCopy | Export-Csv -Path $CsvOutputFilePath -Append -Delimiter ";"
                    Write-Prompt "Subsite added to CSV-file."
                    Write-Host
                }
                else {
                    Write-Line
                    Write-Host
                    Write-Prompt "Sub Site Title:         $($SubSite.Title)"
                    Write-Prompt "Sub Site Url:           $($SubSite.Url)"
                    Write-Prompt "Sub Site Created By:    $($SubSite.Author.Email)"
                    Write-Host
                    Write-DebugInfo "This Sub Site is either on-prem or an App and as such out of scope..."
                    Write-Host
                }
            }
        }
        else {
            Write-Prompt "No subsites or no access to subsites..."
            Write-Host
            $SiteCollection | Export-Csv -Path $CsvOutputFilePath -Append -Delimiter ";"

        }
    
    }

}
Write-DoubleLine
Write-Done
Stop-Transcript