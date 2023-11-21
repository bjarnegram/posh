# ================================
#
# Script to rename files in a SharePoint library
# Files named "file *" will be renamed to "File*"
# Without space between "file" and the number
# Usage: Rename-SPFiles -SiteUrl https://contoso.sharepoint.com/sites/contoso -LibraryName Documents
#
# ================================


[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="The URL of the site to connect to")]
    [string]$SiteUrl,
    [Parameter(Mandatory=$true, HelpMessage="The name of the library to rename files in")]
    [string]$LibraryName
)

# Include Functions
. "$PSScriptRoot\include-functions.ps1"

#Write a header
Write-Header "Files named 'file *' will be renamed to 'File*'"

Connect-PnPOnline -Url $SiteUrl -Interactive

# Get all files in the library named "file *"

$files = Get-PnPListItem -List $LibraryName -PageSize 500
Write-Prompt "Total Number of Items Found: $($files.Count)"

$files = $files | Where-Object { $_.FieldValues.FileLeafRef -like "file *" }
Write-Prompt "Filtered Number of Items Found: $($files.Count)"

# Rename the files
foreach ($file in $files) {
    $newName = $file.FieldValues.FileLeafRef -replace "file ", "File"
    Write-Prompt "Renaming file: $($file.FieldValues.FileLeafRef)) to $($newName)"
    Set-PnPListItem -List $LibraryName -Identity $file.Id -Values @{FileLeafRef = $newName }
}

