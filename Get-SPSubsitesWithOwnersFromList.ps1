# ================================
#
# Script to get subsites from Site Collections
# Included members of <site> Owners group
#
# ================================

#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Get list of subsites with owners from Site Collections

.DESCRIPTION
    Get-SPSubsitesWithOwners is a function that gets a list
    of subsites with members of Site Owners group
    from one or more Site Collections in CSV file

.PARAMETER CsvPath
    Path to Csv-File containing Site Collection
    MCsv-file must have following structure:
    [Site Name;Site Url;Sub Site Name;Sub Site Url;Owner;Expiration Date;Site Status;Provisioning Status;External Collaboration;Confidentiality;Organization;Site Audience;Template;Gdpr;Sensitive Gdpr;Business Area Level;Business Division Level]

.NOTES
    Author:  Bjarne L. Gram
    Email:   bjarne.l.gram@no.abb.com
    Twitter: @bjarnegram
#>

[CmdletBinding()]
param
(
    [Parameter(Mandatory)]
    [string]$CsvPath
)

# Logging
$dateStamp = Get-Date -Format yyyy-MM-dd-HH-mm-ss
$logFile = "Get-SPSubsitesWithOwners-$env:COMPUTERNAME-$dateStamp.log"
$logFile = Join-Path $PSScriptRoot $logFile

Write-Host -ForegroundColor Green "# Starting Transcript to file $logFile"
Start-Transcript -Path $logFile

# Include Functions
. "$PSScriptRoot\include-functions.ps1"

#Debug true - used by include-functions.ps1
$isDebug = $true

Write-Header "Get list of subsites with owners from Site Collections in report from Provisioner"

# Parameters
$CsvFilePath = $CsvPath
if(-not (Test-Path $CsvFilePath))
{
    Write-Prompt
    Write-Important "The file $($CsvFilePath) does not exist."
    Stop-Transcript
    Exit
}

If(-not (Confirm-Action "Has the columns 'Sub Site Name' and 'Sub Site Url' been added to the CSV-file")){
    Write-Prompt
    Write-Important "These columns must be present. Breaking."
    Stop-Transcript
    Exit
}

Write-Prompt "Using CSV-file: $($CsvFilePath)"

$SiteCollections = Import-Csv -Path $CsvFilePath -Delimiter ';'

Write-Prompt "CSV-file contains $($SiteCollections.Count) Site Collections"

foreach($SiteCollection in $SiteCollections)
{
    if($SiteCollection){
        
        $SiteCollectionUrl = $SiteCollection.'Site Url'
        $SiteOwner = $SiteCollection.Owner

        # Open Site Collection and find sub sites
        Connect-PnPOnline -Url $SiteCollectionUrl -Interactive
    
        Write-DoubleLine
        Write-Prompt "Site Collection Name: $($SiteCollection.'Site Name')"
        Write-Prompt "Site Collection Url:  $($SiteCollectionUrl)"
        Write-Prompt "Current Site Collection Owner in CSV: $($SiteOwner)"
        
        # Get Site Collection Admins
        $SCAdmins = Get-PnPSiteCollectionAdmin

        Write-Prompt

        WriteDebug "There are $($SCAdmins.Count) Site Collection Administrators in SharePoint:"
        foreach ($SCAdmin in $SCAdmins) {
            WriteDebug "- $($SCAdmin.Title) <$($SCAdmin.Email)>"
        }
    
        Write-Prompt

        # Get all subwebs (sites) from Site Collection
        $SubWebs = Get-PnPSubWeb -Recurse
        if($SubWebs){
            Write-Prompt "Site Collection $($SiteCollection.'Site Name') contains $($Subwebs.Count) subwebs"
            Write-Prompt

            foreach ($SubWeb in $SubWebs) {
                # Copy of SC Object for addition
                $SCCopy = $SiteCollection.PSObject.Copy()
                $SCCopy.'Sub Site Name' = $SubWeb.Title
                $SCCopy.'Sub Site Url'  = $SubWeb.Url
                Write-Line
                Write-Prompt "Subweb Title: $($SubWeb.Title)"
                Write-Prompt "Subweb Url:   $($SubWeb.Url)"
                Write-Prompt
    
                # Connect to Subweb
                Connect-PnPOnline -Url $SubWeb.Url -Interactive

                # Get Owners and loop through
                $OwnerGroup = Get-PnPGroup -AssociatedOwnerGroup -ErrorAction SilentlyContinue
                if($OwnerGroup){
                    $OwnerMembers = Get-PnPGroupMember -Group $OwnerGroup -ErrorAction SilentlyContinue
                    WriteDebug "AssociatedOwnerGroup is $($OwnerGroup.Title):"
                    if($OwnerMembers.Count -gt 0)
                    {
                        $OwnerString += "["
                        foreach ($OwnerMember in $OwnerMembers) {
                            if($OwnerMember.PrincipalType -eq "User" -and $OwnerMember.Title -ne "System Account")
                            {
                                WriteDebug "- $($OwnerMember.Title) <$($OwnerMember.Email)>"
                                $OwnerString += $($OwnerMember.Email)
                                $OwnerString += ","
                            }
                        }
                        $OwnerString = $OwnerString.Substring(0,($OwnerString.Length - 1))
                        $OwnerString += "]"
                        
                        $SCCopy.Owner = $OwnerString
                        $OwnerString = ""
                    }
                }
    
                $SCCopy | Export-Csv -Path $CsvFilePath -Append -Delimiter ";"
                Write-Prompt "Subsite $($SCCopy.'Sub Site Name') added to CSV-file."
            }
        }
    }

}
Write-DoubleLine
Stop-Transcript