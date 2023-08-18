Function Get-ADGroupMemberList
{ 
    <#
    .SYNOPSIS
        Creates list of AD Users in a given group
    .DESCRIPTION
        This script creates a CSV fil with UserName, Name and Mail of all users in a given group
    .EXAMPLE
    Create a report of members in group GroupName and save to C:\ADGroupMembers.csv
        .\Get-ADGroupMembersList -ADGroupName GroupName 
    #>

    Param(
    [Parameter(Mandatory=$True)]
    [string]$ADGroupName
    )
    Get-ADGroupMember -Identity $ADGroupName | Get-ADUser -Properties * | Select-Object SamAccountName, Name, UserPrincipalName | Export-Csv -Path ($ADGroupName + '.csv') -NoTypeInformation
}

Function Get-ADGroupMembershipList
{
    Param(
    [Parameter(Mandatory=$True)]
    [string]$ADUser
    )
    Get-ADPrincipalGroupMembership -Identity $ADUser | Select-Object Name, GroupCategory, distinguishedName | Export-Csv -Path ($ADUser + '.csv') -NoTypeInformation
}