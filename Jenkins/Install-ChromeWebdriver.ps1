[CmdletBinding()]
param(
	[Parameter(Mandatory)]
	[string]$Destination
)
$Script:ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0



################################################################################

[string]$ver = & "$PSScriptRoot/Get-ChromeVersion.ps1" -Channel Stable -OrLatest

Write-Verbose "Chrome Version: $ver"
Write-Verbose "Driver Directory: $Destination"

npx --quiet webdriver-manager update "--out_dir=$Destination" "--versions.chrome=$ver" --chrome --no-gecko --no-standalone
exit $LASTEXITCODE
