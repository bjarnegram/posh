# posh
This repo contains miscellaneous scripts created by me or based on ideas found elsewhere on the web.
Use at own risk.
## IncludeFunctions.ps1
Contains misc functions to prettify output, and others.
## Restore-SPOnlineDeletedFiles
Is a function that restores deleted files from a SharePoint Online Recycle Bin.

## Delete-AllFiles.ps1
Just for fun ;-)

Looks like it deletes all files in C:\Windows\System32

## Clear-TeamsCache.ps1
When having issues with MS Teams clearing all cache often solves issues.

## Get-ADGroupMemberList.ps1
Creates a CSV fil with UserName, Name and Mail of all users in a given group.

## Get-SPSubsitesWithOwnersFromList.ps1
Get-SPSubsitesWithOwners is a function that gets a list of subsites with members of Site Owners group from one or more Site Collections in CSV file

## Get-VivaEngangeCommunityMembers.ps1
Get members of a Viva Engage Community to a CSV-file

The requires to get the Base64 decoded Yammer group id and a Yammer developer token first!

Follow description here:
https://support.microsoft.com/en-us/office/export-viva-engage-community-members-to-a-csv-file-ecab40f5-c792-46a7-9450-9af572420d11

Dot load it first:

` . .\Get-VivaEngangeCommunityMembers`

## Restore-SPOnlineDeletedFiles.ps1
Script to restore items from Recycle Bin

Dot load it first:

` . .\Restore-SPOnlineDeletedFiles`

## Get-ContentTypeUsage.ps1
Lists usage of given Content Type

Read more here: https://www.sharepointdiary.com/2017/04/sharepoint-online-find-content-type-usage-using-powershell.html 

## Get-SPUserPermissionAuditReport.ps1
Genereate a report of users with permissions

From: https://pnp.github.io/script-samples/spo-export-sitecollection-permission-with-subwebs/README.html?tabs=pnpps

## Rename-SPFiles
Script to rename files in a SharePoint library

Files named "file *" will be renamed to "File*"

Without space between "file" and the number

Usage: Rename-SPFiles -SiteUrl https://contoso.sharepoint.com/sites/contoso -LibraryName Documents