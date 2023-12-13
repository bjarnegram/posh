<#
.Synopsis
 	Function to set time zone and regional settings.
.Description
	Function to set time zone and regional settings to Norwegian
.Example
	C:\PS>Set-SPRegionalSettings -Url "Url to site"
	
.Notes
	Name: Set-SPRegionalSettings
	Author: Bjarne L. Gram
	Last Edit: 2023-12-12
.Link

#Read more: https://www.sharepointdiary.com/2019/06/sharepoint-online-change-regional-settings-using-powershell.html#ixzz8LfRXWkol

#>
Param
(
	[Parameter(Mandatory = $true, HelpMessage = "Url to site")]
	[string]$Url
)

# Parameters - Norway
$LocaleId = 1044
$TimeZoneId = 4
$Time24 = $true
$FirstWeekOfYear = 2
$ShowWeeks = $true
$Collation = 9
$FirstDayOfWeek = 1

# Logging
$dateStamp = Get-Date -Format yyyy-MM-dd-HH-mm-ss
$logFile = "Set-SPRegionalSettings-$dateStamp.log"
Start-Transcript -Path $logFile 

# Include Functions
. "$PSScriptRoot\include-functions.ps1"

# Write Header
Write-Header "Sets regional settings and time zone to Norwegian"
Write-Header "for site $Url"

# Connect to SP Site with current user
Connect-PnPOnline -Url $Url -Interactive

#Get the Web
$Web = Get-PnPWeb -Includes RegionalSettings, RegionalSettings.TimeZones, RegionalSettings.Time24, RegionalSettings.FirstWeekOfYear, RegionalSettings.ShowWeeks, RegionalSettings.Collation, RegionalSettings.FirstDayOfWeek

#Get the Timezone
$TimeZone = $web.RegionalSettings.TimeZones | Where-Object { $_.Id -eq $TimeZoneId }
	
#Update Regional Settings
$Web.RegionalSettings.TimeZone = $TimeZone
$Web.RegionalSettings.LocaleId = $LocaleId
$Web.RegionalSettings.Time24 = $Time24
$Web.RegionalSettings.FirstWeekOfYear = $FirstWeekOfYear
$Web.RegionalSettings.FirstDayOfWeek = $FirstDayOfWeek
$Web.RegionalSettings.ShowWeeks = $ShowWeeks
$Web.RegionalSettings.Collation = $Collation
$Web.Update()
Invoke-PnPQuery

#Stop Transcript
Stop-Transcript

