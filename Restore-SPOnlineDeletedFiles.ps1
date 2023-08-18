# ================================
#
# Script to restore items from Recycle Bin
#
# ================================

#Requires -RunAsAdministrator

Function Restore-SPOnlineDeletedFiles {

    <#
    .SYNOPSIS
        Restore deleted files from SharePoint Online Recycle Bin.

    .DESCRIPTION
        Restore-SPOnlineDeletedFiles is a function that restores deleted files
        from a SharePoint Online Recycle Bin.

    .PARAMETER SiteCollectionUrl
        The SharePoint Online Site Collection the files are to be restored from.
        The user running the function, and logging on interactively, must be a
        Site Collection Administrator.

    .PARAMETER DeletedByEmail
        The email adress of the user that deleted the items.

    .PARAMETER StartDate
        Restore files deleted after this date.
    
    .PARAMETER EndDate
        Restore files deleted before this date.

    .PARAMETER FileType
        Restore files of this type.

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
        [string]$SiteCollectionUrl,
        [string]$DeletedByEmail,
        [DateTime]$StartDate,
        [DateTime]$EndDate,
        [string[]]$FileType
    )

        # Logging
        $dateStamp = Get-Date -Format yyyy-MM-dd-HH-mm-ss
        $logFile = "restore-log-$env:COMPUTERNAME-$dateStamp.log"
        $logFile = Join-Path $PSScriptRoot $logFile
        
        #Debug true
        $isDebug = $true

        Write-Host -ForegroundColor Green "# Starting Transcript to file $logFile"
        # Start-Transcript -Path $logFile
        
        # Include Functions
        . "$PSScriptRoot\include-functions.ps1"
        
        Write-Header "Script to restore files from SharePoint online recycle bin"
        
        $siteUrl = $SiteCollectionUrl.TrimEnd('/')
        $conf = Confirm-Action "Is the URL to the Site Collection: $siteUrl correct?"
        
        if($conf)
        {
            Write-Prompt
        
            Connect-PnPOnline -Url $siteUrl -Interactive
            
            Write-Prompt
            
            $count = (Get-PnPRecycleBinItem).count
            Write-Prompt "The total number of files in the Recycle bin is: $count"
            Write-Prompt

            WriteDebug "Filter applied:"
            Write-Line
            WriteDebug "Files deleted by user with Email: $DeletedByEmail"
            WriteDebug "Files deleted after: $StartDate"
            WriteDebug "Files deleted before: $EndDate"
            WriteDebug "Files deleted of type: $FileType"

            $FilterString = ""
            if($StartDate -and $EndDate){
                $FilterString = '($_.DeletedDate -gt $StartDate -and $_.DeletedDate -lt $EndDate)'
            }
            elseif($StartDate){
                $FilterString = '$_.DeletedDate -gt $StartDate'
            }
            elseif($EndDate){
                $FilterString = '$_.DeletedDate -lt $EndDate'
            }

            if(($StartDate -or $EndDate) -and $DeletedByEmail){
                $FilterString = $FilterString + ' -and $_.DeletedByEmail -eq $DeletedByEmail'
            }
            elseif($DeletedByEmail){
                $FilterString = '$_.DeletedByEmail -eq $DeletedByEmail'
            }

            if(($StartDate -or $EndDate -or $DeletedByEmail) -and $FileType){
                $FilterString = $FilterString + ' -and ($_.LeafName -like $FileType)'
            }
            elseif($FileType){
                $FilterString = '$_.LeafName -like $FileType'
            }

            if($FilterString){
                $DeletedItems = Get-PnPRecycleBinItem | Where-Object {Invoke-Expression($FilterString)}
            }
            else{
                $DeletedItems = Get-PnPRecycleBinItem
            }
            WriteDebug
            WriteDebug "Deleted Items:"
            Write-Line
            ForEach($Item in $DeletedItems)
            {
                WriteDebug "$($Item.LeafName)"
            }

            $conf = Confirm-Action "Do you want to restore these files"

            if($conf){
            #Restore all deleted items from the given path to its original location

            ForEach($Item in $DeletedItems)
            {
                #Get the Original location of the deleted file
                $OriginalLocation = "/"+$Item.DirName+"/"+$Item.LeafName
                If($Item.ItemType -eq "File")
                {
                    $OriginalItem = Get-PnPFile -Url $OriginalLocation -AsListItem -ErrorAction SilentlyContinue
                }
                Else #Folder
                {
                    $OriginalItem = Get-PnPFolder -Url $OriginalLocation -ErrorAction SilentlyContinue
                }
                #Check if the item exists in the original location
                If($OriginalItem -eq $null)
                {
                    #Restore the item
                    $Item | Restore-PnpRecycleBinItem -Force
                    Write-Host "Item '$($Item.LeafName)' restored Successfully!" -f Green
                }
                Else
                {
                    Write-Host "There is another file with the same name.. Skipping $($Item.LeafName)" -f Yellow
                }
            }

            #Read more: https://www.sharepointdiary.com/2019/02/sharepoint-online-powershell-to-restore-deleted-items-from-recycle-bin.html#ixzz7hh4yEV1D
            }
            else {
                Write-Important "Exiting..."
            }
        }
        else {
            Write-Important "Wrong URL provided!"
            Write-Important "Exiting..."
        }
        
    }





