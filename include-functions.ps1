# ==============================
# 
# A set of usefule functions for PowerShell scripts
#
# ==============================

$isDebug = $true

Function Write-Line {
	Write-Host -ForegroundColor Green "# --------------------------------------------------------------------"
}

Function Write-DoubleLine {
	Write-Host -ForegroundColor Green "# ===================================================================="
}

Function Write-Notification ($text) {
	Write-Host -ForegroundColor Yellow "+"
	Write-Host -ForegroundColor Yellow "+ $text"
	Write-Host -ForegroundColor Yellow "+"
}

Function Write-Important ($text) {
	Write-Host -ForegroundColor Red "!"
	Write-Host -ForegroundColor Red "! $text"
	Write-Host -ForegroundColor Red "!"
}

Function Get-Response ($text) {
	Write-Host -ForegroundColor White ">"
	Write-Host -ForegroundColor White -NoNewline "> $text "

	$reply = Read-Host
	return $reply
}

Function Confirm-Action ($text) {
	Write-Host -ForegroundColor White ">"
	Write-Host -ForegroundColor White -NoNewline "> $text [y/n]: "
	$reply = Read-Host
	if ( $reply -match "[yY]" ) { 
		return $true
	}
	else {
		return $false
	}
	Write-Host -ForegroundColor White ">"
}

Function Write-DebugInfo ($text) {
	if ($isDebug) {
		Write-Host -ForegroundColor Green "# $text"
	}
}

Function Write-Prompt ($text) {
	Write-Host -ForegroundColor White "> $text"
}

Function Write-Pause ($text) {
	if ($isDebug) {
		Write-DebugInfo $text
		Pause
	}
}

Function Write-Done () {
	if ($isDebug) {
		Write-DebugInfo "Done..."
		#Pause
	}
}

Function Write-Header ($text) {
	Write-Host
	Write-DoubleLine
	Write-DebugInfo
	Write-DebugInfo $text
	Write-DebugInfo
	Write-DoubleLine
	Write-Host
}

Function Append-CsvString ($string1, $string2) {
	$string1 += ";"
	$string1 += $string2
}

Function Get-FQDN {
	$path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
	$hostname = (Get-ItemProperty -Path $path -Name "Hostname")."Hostname"
	$domainname = (Get-ItemProperty -Path $path -Name "Domain")."Domain"
	$fqdn = $hostname + "." + $domainname
	return $fqdn
}

Function Get-HostName {
	$path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
	$hostname = (Get-ItemProperty -Path $path -Name "Hostname")."Hostname"
	return $hostname
}

# Function Used for variables in Azure DevOps containing other variables
Function Expand-Variable ($text) {
	$text = $text -replace '[()]', ''
	$value = $ExecutionContext.InvokeCommand.ExpandString($text)
	return $value
}

Function IIf($If, $IfTrue, $IfFalse) {
    If ($If) {If ($IfTrue -is "ScriptBlock") {&$IfTrue} Else {$IfTrue}}
    Else {If ($IfFalse -is "ScriptBlock") {&$IfFalse} Else {$IfFalse}}
}
Function Add-UserToLocalGroup {
	<# 
	.SYNOPSIS 
		Add a user to a local group
	.DESCRIPTION
		This function adds a user to a local group with check and error handling
	.SYNTAX
		AddUserToLocalGroup UserName<String> Group<String>
	.Notes 
		Author : Bjarne L. Gram 
	#> 
	param (
		[String]
		$Member,
		[String]
		$Group
	)

	Write-Pause "Assign user $Member to local group $Group"
	$userExistInGroup = Get-LocalGroupMember -Group $Group -Member $Member -ErrorAction SilentlyContinue
	if ($userExistInGroup) {
		Write-DebugInfo "$Member is a member of local group $Group"
	}
	else {
		Add-LocalGroupMember -Group $Group -Member $Member
		Write-DebugInfo "User $Member added to local group $Group"
	}
}

Function Add-LocalAccount ($user) {
	<# 
		.SYNOPSIS 
			Create a new Local User
		.DESCRIPTION
			This function creates a new local user account if it doesn't exist
		.SYNTAX
			Add-LocalAccount UserName<String>
		.Notes 
			Author : Bjarne L. Gram 
    #> 
	$userExist = Get-LocalUser -Name $user -ErrorAction SilentlyContinue
	if ($userExist) {
		Write-Notification "The user account $user allready exists."
	}
	else {
		Write-Notification "Input password for Service Account: "
		$Password = Read-Host -AsSecureString
		New-LocalUser $user -Password $Password
	}

}

Function Set-RegistryKey {
	<# 
	.SYNOPSIS 
		Set a registry key value
	.DESCRIPTION
		This function sets a registry key value and creates the key and/or property if neccessary
	.SYNTAX
		Set-RegistryKey Key<String> Name<String> Value<String>
	.Notes 
		Author : Bjarne L. Gram 
	#> 
	param (
		[Parameter(Mandatory = $true)]
		[String] $Key,
		[Parameter(Mandatory = $true)]
		[String] $Name,
		[Parameter(Mandatory = $true)]
		[String] $Value
	)

	Write-Header "This function sets a registry key value and creates the key and/or property if neccessary"

	if (Test-Path $Key) {
		Write-DebugInfo "Registry key $Key exists"
		Write-Host
	}
	else {
		Write-DebugInfo "Registry key $Key doesn't exist!"
		Write-DebugInfo "Hit Ctrl-C to break"
		Pause
	}

	$regParamExists = Get-ItemProperty $Key -Name $Name -ErrorAction SilentlyContinue
	if ($regParamExists) {
		$regParamValue = Get-ItemPropertyValue $Key -Name $Name -ErrorAction SilentlyContinue
		Write-DebugInfo "Registry parameter $Name exists and the value is $regParamValue"
		Write-Host
	}
	else {
		Write-DebugInfo "Registry parameter $Name doesn't exist, creating it"
		New-ItemProperty $Key -Name $Name -PropertyType DWORD
	}

	if ($regParamValue -ne $Value) {
		Write-Prompt "Setting registry key $Key paramter $Name to value $Value"
		Write-Host
		Set-ItemProperty $Key -Name $Name -Value $Value

		Write-Notification "This will require a restart to be set"
	}
	else {
		Write-Prompt "The registry current value and new value are identical."
		Write-Prompt "Skipping any changes"
	}

	Write-Host
	Write-Done
}

Function Get-InternetProxy { 
	<# 
            .SYNOPSIS 
                Determine the internet proxy address from Registry
            .DESCRIPTION
                This function allows you to determine the the internet proxy address used by your computer
            .EXAMPLE 
                Get-InternetProxy
            .Notes 
                Author : Antoine DELRUE 
                WebSite: http://obilan.be 
    #> 

	$proxies = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings').proxyServer

	if ($proxies) {
		if ($proxies -ilike "*=*") {
			$proxies -replace "=", "://" -split (';') | Select-Object -First 1
		}

		else {
			"http://" + $proxies
		}
	}    
	else {
		"No proxies detected"
	}
}

function Test-Cred {
           
	[CmdletBinding()]
	[OutputType([String])] 
       
	Param ( 
		[Parameter( 
			Mandatory = $false, 
			ValueFromPipeLine = $true, 
			ValueFromPipelineByPropertyName = $true
		)] 
		[Alias( 
			'PSCredential'
		)] 
		[ValidateNotNull()] 
		[System.Management.Automation.PSCredential]
		[System.Management.Automation.Credential()] 
		$Credentials
	)
	$Domain = $null
	$Root = $null
	$Username = $null
	$Password = $null
      
	If ($Credentials -eq $null) {
		Try {
			$Credentials = Get-Credential "domain\$env:username" -ErrorAction Stop
		}
		Catch {
			$ErrorMsg = $_.Exception.Message
			Write-Warning "Failed to validate credentials: $ErrorMsg "
			Pause
			Break
		}
	}
      
	# Checking module
	Try {
		# Split username and password
		$Username = $credentials.username
		$Password = $credentials.GetNetworkCredential().password
  
		# Get Domain
		$Root = "LDAP://" + ([ADSI]'').distinguishedName
		$Domain = New-Object System.DirectoryServices.DirectoryEntry($Root, $UserName, $Password)
	}
	Catch {
		$_.Exception.Message
		Continue
	}
  
	If (!$domain) {
		Write-Warning "Something went wrong"
	}
	Else {
		If ($domain.name -ne $null) {
			return "Authenticated"
		}
		Else {
			return "Not authenticated"
		}
	}
}

Function Copy-WithProgress {
	<# 
    .SYNOPSIS 
        Copy files with progress-bar
    .DESCRIPTION
        This function copies all files from $Source to $Destination while displaying a progress-bar
    .EXAMPLE 
        Copy-WithProgress C:\temp d:\temp $true
    .Notes 
        Author : Dr Scripto with modifications by Budmod project
        WebSite: https://devblogs.microsoft.com/scripting/build-a-better-copy-item-cmdlet-2/ 
#> 
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory = $true)]
		$Source,
		[Parameter(Mandatory = $true)]
		$Destination,
		[Parameter(Mandatory = $true)]
		$Force
	)

	$Source = $Source.tolower()
	$Filelist = Get-Childitem "$Source" -Recurse
	$Total = $Filelist.count
	$Position = 0

	foreach ($File in $Filelist) {
		$Filename = $File.Fullname.tolower().replace($Source, '')
		$DestinationFile = Join-Path $Destination $Filename
		Write-Progress -Activity "Copying data from '$source' to '$Destination'" -Status "Copying File $Filename" -PercentComplete (($Position / $total) * 100)
		if ($Force) { Copy-Item $File.FullName -Destination $DestinationFile -Force }
		else { Copy-Item $File.FullName -Destination $DestinationFile }
        
		$Position++
	}
}

Function Get-NetshSetup($sslBinding = '0.0.0.0:443') {
	<# 
    .SYNOPSIS 
        Get SSL Setup
    .DESCRIPTION
        This function uses netsh hhtp show to get all SSL setup
    .EXAMPLE 
        Get-NetshSetup 0.0.0.0:443
    .Notes 
        WebSite: https://toreaurstad.blogspot.com/2018/10/working-with-netsh-http-sslcert-setup.html 
#> 

	$sslsetup = netsh http show ssl $sslBinding

	$sslsetupKeys = @{}

	foreach ($line in $sslsetup) {
		if ($line -ne $null -and $line.Contains(': ')) {
    
			$key = $line.Split(':')[0]
			$value = $line.Split(':')[1]
			if (!$sslsetupKeys.ContainsKey($key)) {
				$sslsetupKeys.Add($key.Trim(), $value.Trim()) 
			}
		} 
	}

	return $sslsetup
}

Function Get-MyTeams {
	# Function to get all my teams in microsoft teams
	# Requires Microsoft Teams module to be installed
	# Requires you to be logged in to Microsoft Teams
	# Requires you to have a license for Microsoft Teams
	# Requires you to have at least one team in Microsoft Teams

	Write-Header "Requires you to be logged in to Microsoft Teams"

	# Get all teams where you are a member
	$MyTeams = Get-Team -User $(Get-ADUser -Identity $env:USERNAME).UserPrincipalName

	# Return all teams
	Return $MyTeams
}

Function Get-MyEmailAdress {
	$(Get-ADUser -Identity $env:USERNAME).UserPrincipalName
}
