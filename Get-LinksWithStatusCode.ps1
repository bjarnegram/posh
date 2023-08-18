function Get-LinksWithStatusCode {
	<#
.Synopsis
	Get all links from a web page and return the status code for each link.
.Description
	Get all links from a web page and return the status code for each link.
	Result stored in CSV file specified in Path
.Example
	C:\PS>Get-LinksWithStatusCode -Url "http://www.google.com" -Path "C:\Temp\GoogleLinks.csv"

.Notes
	Name: Get-LinksWithStatusCode
	Author: Bjarne L. Gram
	Last Edit: 2023-07-14
.Link

	Copied from: https://gist.github.com/ciphertxt/5244787

.Inputs
	Url - Url to site to get links from
	Path - Path to folder to store CSV file  in
.Outputs
	CSV file with links and status code
#>
	[CmdletBinding()]

	Param
	(
		[Parameter(Mandatory = $true, HelpMessage = "Enter a Url")]
		[string]$Url,
		[Parameter(Mandatory = $true, HelpMessage = "Enter a Path")]
		[string]$Path
	)

	# Include Functions
	. "$PSScriptRoot\include-functions.ps1"
        
	Write-Header "Script to find links on a page"
			
	$domain = $Url.Split('/')[2]
	$now = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
	$Path = $Path + "\" + $domain + "_" + $now + ".csv"
	$links = (Invoke-WebRequest -Uri $Url).Links | Select-Object -ExpandProperty href -Unique
	foreach ($link in $links) {
		Try {
			$statusCode = Invoke-WebRequest -Uri $link -MaximumRedirection 0 -ErrorAction SilentlyContinue | Select -ExpandProperty StatusCode
		}
		Catch {
			$_
			$statusCode = $_.Exception.Response.StatusCode.Value__
		}
		$link | Add-Member -MemberType NoteProperty -Name StatusCode -Value $statusCode -PassThru

	}
	$links | Export-Csv -Path $Path -NoTypeInformation
    
} #End function