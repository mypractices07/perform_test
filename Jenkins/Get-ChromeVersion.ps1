<#
.SYNOPSIS
Retrieves the version string for the current Google Chrome installation.

.DESCRIPTION
Reads the installed version of Google Chrome from the appropriate,
updater-managed registry key.

If the -OrLatest parameter is specified and the version of Chrome cannot be
found, the word `latest` will be output instead. Without -OrLatest, the same
scenario will instead cause an error.

The -Channel parameter can be used to work with a non-production release of
Chrome. By default, the "Stable" channel is assumed.

Based on the batch script from this Stack Overflow answer:
https://stackoverflow.com/questions/50880917/how-to-get-chrome-version-using-command-prompt-in-windows/51773107#51773107
#>
[OutputType([string])]
[CmdletBinding()]
param(
	# Can be Stable, Beta, or Dev.
	#
	# See https://www.chromium.org/getting-involved/dev-channel#TOC-How-do-I-choose-which-channel-to-use- for details.
	[ValidateSet('Stable', 'Beta', 'Dev')]
	[string]$Channel = 'Stable',

	[switch]$OrLatest
)
Set-StrictMode -Version 2.0

# Map the requested channel name to the registry key name
[string]$guid = $(
	switch -Exact ($Channel) {
		'Stable' { '{8A69D345-D564-463c-AFF1-A69D9E530F96}'; break }
		'Beta' { '{8237E44A-0054-442C-B6B6-EA0509993955}'; break }
		'Dev' { '{401C381F-E0DE-4B85-8BD8-3F3F14FBDA57}'; break }
		default { throw 'unreachable!' }
	}
)

# Determine version of Chrome installation
[string]$x86 = $(if ([Environment]::Is64BitProcess) { 'WOW6432Node' })
[string]$key = "HKLM:/SOFTWARE/$x86/Google/Update/Clients/$guid"
[string]$ver = Get-ItemPropertyValue -LiteralPath $key -Name pv -ErrorAction Ignore

# Output the result (or an error)
if (!$ver) {
	if (!$OrLatest) {
		[string]$msg = "The registry entry for the $Channel release of Google Chrome is either empty or does not exist."
		Write-Error $msg -Category ObjectNotFound -ErrorId 'ChromeVersionNotFound'
		exit 1
	}
	$ver = 'latest'
}
return $ver
