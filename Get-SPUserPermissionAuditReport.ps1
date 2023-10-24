
## From: https://pnp.github.io/script-samples/spo-export-sitecollection-permission-with-subwebs/README.html?tabs=pnpps

$BasePath = "C:\temp\SitePermission\"
$DateTime = "{0:dd_MM_yy}_{0:HH_mm_ss}" -f (Get-Date)
$CSVPath = $BasePath + "\sitepermissions" + $DateTime + ".csv"
$global:permissions = @()

Function ConnectToSPSite() {
    try {
        $SiteUrl = Read-Host "Please enter Site URL"
        if ($SiteUrl) {
            Write-Host "Connecting to Site :'$($SiteUrl)'..." -ForegroundColor Yellow  
            Connect-PnPOnline -Url $SiteUrl -Interactive
            Write-Host "Connection Successfull to site: '$($SiteUrl)'" -ForegroundColor Green              
            WebPermission
        }
        else {
            Write-Host "Site URL is empty." -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error in connecting to Site:'$($SiteUrl)'" $_.Exception.Message -ForegroundColor Red               
    } 
}

Function WebPermission {
    try {
        $Web = Get-PnPWeb -Includes RoleAssignments
        CheckPermission $Web    
        SubWebPermission        
    }
    catch {
        Write-Host "Error in getting web:" $_.Exception.Message -ForegroundColor Red               
    } 
}

Function CheckPermission ($obj) {
    try {
        Write-Host "Getting permission for the :'$($obj.Url)'..." -ForegroundColor Yellow
        Get-PnPProperty -ClientObject $obj -Property HasUniqueRoleAssignments, RoleAssignments      
        $HasUniquePermissions = $obj.HasUniqueRoleAssignments
   
        Foreach ($RoleAssignment in $obj.RoleAssignments) {                
            Get-PnPProperty -ClientObject $RoleAssignment -Property RoleDefinitionBindings, Member
                  
            $PermissionType = $RoleAssignment.Member.PrincipalType
                     
            $PermissionLevels = $RoleAssignment.RoleDefinitionBindings | Select -ExpandProperty Name
                
            If ($PermissionLevels.Length -eq 0) { Continue } 

            If ($PermissionType -eq "SharePointGroup") {
                    
                $GroupMembers = Get-PnPGroupMember -Identity $RoleAssignment.Member.LoginName                                  
                If ($GroupMembers.count -eq 0) { Continue }
                ForEach ($User in $GroupMembers) {
                    $global:permissions += New-Object PSObject -Property ([ordered]@{
                            'Site URL'           = $obj.Url
                            'Site Title'         = $obj.Title
                            Title                = $User.Title 
                            PermissionType       = $PermissionType
                            PermissionLevels     = $PermissionLevels -join ","
                            Member               = $RoleAssignment.Member.Title     
                            HasUniquePermissions = $HasUniquePermissions                                     
                        })  
                }
            }                        
            Else {                                        
                $global:permissions += New-Object PSObject -Property ([ordered]@{
                        'Site URL'           = $obj.Url
                        'Site Title'         = $obj.Title
                        Title                = $RoleAssignment.Member.Title 
                        PermissionType       = $PermissionType
                        PermissionLevels     = $PermissionLevels -join ","
                        Member               = "Direct Permission"      
                        HasUniquePermissions = $HasUniquePermissions                             
                    })  
            }                            
        }                                  
        BindingtoCSV($global:permissions)
        $global:permissions = @()
        Write-Host "Getting permission successfully for the :'$($obj.Url)'..." -ForegroundColor Green
    }
    catch {
        Write-Host "Error in checking permission" $_.Exception.Message -ForegroundColor Red               
    } 
}

Function SubWebPermission {
    try {    
        $subwebs = Get-PnPSubWeb -Recurse  
        foreach ($subweb in $subwebs) { 
            Write-Host "Connecting to Subweb :'$($subweb.Url)'..." -ForegroundColor Yellow
            Connect-PnPOnline -Url $subweb.Url -Interactive
            Write-Host "Connection successfully to Subweb :'$($subweb.Url)'..." -ForegroundColor Green
            CheckPermission $subweb
        } 
    }
    catch {
        Write-Host "Error in connecting to sub web" $_.Exception.Message -ForegroundColor Red               
    } 
}

Function BindingtoCSV {
    [cmdletbinding()]
    param([parameter(Mandatory = $true, ValueFromPipeline = $true)] $Global)       
    $global:permissions | Export-Csv $CSVPath -NoTypeInformation -Append            
}

ConnectToSPSite
