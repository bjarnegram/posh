#####################################################################
##### JUST FOR FUN - only displays text - does not delete files #####
#####################################################################

# Include Functions
. "$PSScriptRoot\include-functions.ps1"

cls

$dir = Get-ChildItem -File -Path C:\Windows\System32\
$fc = $dir.Count

Write-Header "D E L E T I N G   A L L   D A T A   O N   C:\"

Write-Header "D E L E T I N G   A L L   D A T A   O N   C:\"

Write-Important "D E L E T I N G   $fc   F I L E S !"

for ($i = 1; $i -le $fc; $i++ ) {
    $pc = [math]::Round(($i/$fc)*100)
    Write-Progress -Activity "D E L E T I N G   A L L   D A T A   O N   C:\" -Status "$pc% Complete:" -PercentComplete $pc
    Write-Host -ForegroundColor Red "Now deleting file:" $dir[$i].Name
    Start-Sleep -Milliseconds 100
}
