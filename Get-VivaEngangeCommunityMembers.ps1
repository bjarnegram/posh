#####################################################################
## Script to get members of a Viva Engange Community in a CSV-file ##
#####################################################################

Function Get-VivaEngangeCommunityMembers {
     <#
    .SYNOPSIS
        Get members of a Viva Engage Community

    .DESCRIPTION
        Get-VivaEngangeCommunityMembers is a function that get a CSV-file with
        all members of a given Viva Engage Community.
        Based on https://support.microsoft.com/en-us/office/export-viva-engage-community-members-to-a-csv-file-ecab40f5-c792-46a7-9450-9af572420d11

    .PARAMETER CommunityID
          Find the community's group ID:
          In Viva Engage on the web, select a community.
          In the URL in the address bar, copy all of the text after groups/ and before /all. 
          This is the base 64 encoding; for example, the base 64 encoding in the following URL is in bold:
          https://web.yammer.com/main/groups/eyJfdHlwZSI6Ikdyb3VwIiwiaWQiOiI5NzM0ODQ4N0TEyIn/all

          After copying the base 64 encoding, use an online tool to decode base 64.
          One such tool is https://www.base64decode.org/
          Using the base 64 encoding example from the previous step, an online decoding tool would decode it as follows:
          {"_type":"Group","id":"9734848512"}
          The group ID in this example would be 9734848512.

    .PARAMETER Token
          Register new application in Yammer at
          https://www.yammer.com/abb.com/client_applications/ 
          and get a developer-token    

    .EXAMPLE
        Restore-SPOnlineDeletedFiles -SiteCollectionUrl 'https://contoso.sharepoint.com/sites/sitecollection1'

    .EXAMPLE
        Restore-SPOnlineDeletedFiles -SiteCollectionUrl 'https://contoso.sharepoint.com/sites/sitecollection1' -DeletedByEmail 'user@contoso.com'

    .EXAMPLE
        Restore-SPOnlineDeletedFiles -SiteCollectionUrl 'https://contoso.sharepoint.com/sites/sitecollection1' -DeletedByEmail 'user@contoso.com' -FileType '*.docx'

    .NOTES
        Author:  Bjarne L. Gram
        Email: bjarne.l.gram@no.abb.com
        Twitter: @bjarnegram
#>

[CmdletBinding()]
param
(
    [Parameter(Mandatory)]
    [string]$CommunityID,
    [string]$Token
)

     # Include Functions
     . "$PSScriptRoot\include-functions.ps1"

     Write-Header "Get members of a Viva Engage Community"

     Write-Important "Read SYNOPSIS in PS1 file to prepare for using this script!"

     $GroupId = $CommunityID

     $Headers = @{ "Authorization" = "Bearer " + $Token }
     $GroupCycle = 1
     DO {
          $GetMoreGroupsUri = "https://www.yammer.com/api/v1/users/in_group/$GroupId.xml?page=$GroupCycle"
          Write-DebugInfo ("REST API CALL : $GetMoreGroupsUri")
          [xml]$Xml = ((Invoke-WebRequest -Uri $GetMoreGroupsUri -Method Get -Headers $Headers).content)
          $YammerGroups += $Xml.response.users.user
          $GroupCycle ++
          $GroupCount += $Xml.response.users.user.count
          Write-DebugInfo ("GROUPMEMBER COUNT : $GroupCount")
     }
     While ($Xml.response.users.user.count -gt 0)
     $YammerGroups | Where-Object { $_ } | Export-Csv "$GroupId.csv" -Delimiter ","
}

