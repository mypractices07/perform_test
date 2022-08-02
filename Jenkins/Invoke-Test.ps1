using namespace System.IO

[CmdletBinding()]
param(
	[Parameter(Mandatory)][string]$LiteralPath,
	[string[]]$TestDocuments,
	[ValidateRange(-1, [int]::MaxValue)][int]$Attempt = -1,
	[switch]$DeleteBatchData, # TODO: when powershell is running interactively, this option should require confirmation
	[switch]$DeleteSweepFolder
)
$Script:ErrorActionPreference = 'Stop'
$Script:VerbosePreference = $VerbosePreference
Set-StrictMode -Version 2.0

New-Variable BatchData "$Env:LOCALAPPDATA\Hyland\Capture.Desktop\Batches" -Option Constant -Scope Script
New-Variable SweepFolder 'C:\Sweep' -Option Constant -Scope Script

################################################################################
###                                 Helpers                                  ###
################################################################################

function Assert-EnvironmentVariables {
	[OutputType()]
	param([Parameter(Mandatory)][string[]]$Names)

	[string[]]$unset = $Names | Where-Object { !(Test-Path -LiteralPath "env:$_") }
	if ($unset) {
		[string]$msg = "Required environment variable$(if (@($unset).Count -gt 1) {'s'}) not set: $unset"
		Write-Error $msg -Category InvalidArgument
	}
}

function Invoke-JMeter {
	[OutputType()]
	param(
		[Parameter(Mandatory)][string]$LiteralPath,
		[Parameter(Mandatory)][string]$Destination,
		[Parameter(Mandatory)][string]$LogFile
	)

	[string[]]$opts = @(
		'--nongui'
		'--testfile', $LiteralPath
		'--logfile', $Destination
		'--jmeterlogfile', $LogFile
		'--loglevel', 'DEBUG'
		# Using properties--instead of environment variables--simplifies access from within JMeter :(
		'--jmeterproperty', "APP_URL=$Env:APP_URL"
		'--jmeterproperty', "IDP_USER=$Env:IDP_USER"
		'--jmeterproperty', "IDP_PASSWD=$Env:IDP_PASSWD"
		'--jmeterproperty', "CHROMEDRIVER_PATH=$Env:CHROMEDRIVER_PATH"
	)
	Write-Verbose "+ jmeter $($opts -creplace '^.*\s.*$', '"$0"')" # FIXME: When run manually--i.e. not on Jenkins--this exposes the password

	# Jenkins, when starting powershell, redirects the stderr character stream into the powershell error record stream.
	# ^^ We don't want that here (or anywhere, really--especially not when running the shell interactively, which jenkins also does...).
	# The need to undo that is the reason we aren't just using `jmeter @opts` here.
	$Local:ErrorActionPreference = 'Continue'
	jmeter @opts 2>&1 | ForEach-Object { $Error.Remove($_); "$_".Trim("`r`n".ToCharArray()) } | Write-Host
}

########################################
### Filesystem Helpers

function Clear-Filesystem {
	[OutputType()]
	[CmdletBinding()]
	param()

	function ClearIfNecessary {
		param(
			[Parameter(Mandatory)][string]$LiteralPath,
			[switch]$File,
			[switch]$Recurse
		)
		if (Get-ChildItem -LiteralPath $LiteralPath -Force -File:$File -ErrorAction Ignore | Select-Object -First 1) {
			Write-Warning "Clearing: $LiteralPath"
			Get-ChildItem -LiteralPath $LiteralPath -Force -File:$File -OutVariable deleted | Remove-Item -Force -Recurse:$Recurse
			Write-Verbose ('Deleted {0:N0} item{2} from {1}.' -f @($deleted).Count, $LiteralPath, $(if (@($deleted).Count -ne 1) {'s'}))
		} else {
			Write-Verbose "Nothing to delete: $LiteralPath"
		}
	}

	if ($Script:DeleteBatchData) { ClearIfNecessary -LiteralPath $Script:BatchData -Recurse }
	if ($Script:DeleteSweepFolder) { ClearIfNecessary -LiteralPath $Script:SweepFolder -File }
}

function Clear-PreviousOutput {
	[OutputType()]
	param(
		[Parameter(Mandatory)][string]$OutFile,
		[Parameter(Mandatory)][string]$LogFile
	)

	# Delete the previous sample outputs, if any.
	Get-Item -LiteralPath $OutFile -ErrorAction Ignore | Remove-Item -Verbose:$VerbosePreference

	# Rename the previous jmeter log, if any.
	[FileInfo]$logitem = Get-Item -LiteralPath $LogFile -ErrorAction Ignore
	if ($logitem) {
		[string]$namefmt = data { '{0}.#ERR-{1}{2}' }
		[string]$namepat = $namefmt -f [WildcardPattern]::Escape($logitem.BaseName), '*', [WildcardPattern]::Escape($logitem.Extension)
		[int]$n = @(Resolve-Path -Path $namepat).Count + 1
		Rename-Item -LiteralPath $logfile -NewName ($namefmt -f $logitem.BaseName, $n, $logitem.Extension) -Verbose:$VerbosePreference
	}
}

function Sync-SweepFolder {
	[OutputType()]
	[CmdletBinding()]
	param([string[]]$Documents)

	if ($Documents) {
		$null = New-Item -Path $Script:SweepFolder -ItemType Directory -Force
		Write-Verbose ((@('Copying documents from:') + $Documents) -join "`n  - ")
		# TODO: auto-rename on conflict
		[FileInfo[]]$copied = Get-ChildItem -Path $Documents -File | Copy-Item -Destination $Script:SweepFolder -PassThru
		Write-Verbose ('Copied {0:N0} documents to {1}.' -f @($copied).Count, $Script:SweepFolder)
	}
}


################################################################################
###                                   Main                                   ###
################################################################################

function Main {
	[CmdletBinding()]
	param()

	[string]$testname = [Path]::GetFileNameWithoutExtension($Script:LiteralPath)
	[string]$outfile, [string]$logfile = "$testname.csv", "$testname.jmeter.log"

	# Prepare filesystem for JMeter
	Clear-PreviousOutput -OutFile $outfile -LogFile $logfile
	Clear-Filesystem
	Sync-SweepFolder -Documents ($Script:TestDocuments | Where-Object { "$_".Trim() })

	# Run JMeter
	Write-Host ('-' * 80)
	Invoke-JMeter -LiteralPath $Script:LiteralPath -Destination $outfile -LogFile $logfile
	Write-Host ('-' * 80)

	# Make sure we didn't get stiffed
	if (!(Test-Path -LiteralPath $outfile -PathType Leaf) -or !(Test-Path -LiteralPath $logfile -PathType Leaf)) {
		[string]$msg = "JMeter did not produce the expected output files!`nTest: $(Resolve-Path -LiteralPath $Script:LiteralPath)`nPath: $PWD"
		Write-Error $msg -Category InvalidResult
	}

	# Report success/failure
	$all = Import-Csv -LiteralPath $outfile
	if ($all | Where-Object success -ne true -OutVariable failed) {
		# Report failure
		Write-Host "Performance test failed with $(@($failed).Count) error$(if (@($failed).Count -ne 1) {'s'})!"
		$failed | Format-List
		if ($Attempt -ge 0) {
			[int]$sleepFor = 20 * [Math]::Pow(1.75, $Attempt)
			Write-Host ('Sleeping for {0:N0} sec' -f $sleepFor)
			Start-Sleep -Seconds $sleepFor
		}
		exit 1
	}
	# Write an informative success message
	[long]$ms = $all | Measure-Object timeStamp -Maximum -Minimum | ForEach-Object { $_.Maximum - $_.Minimum }
	[int]$threads = @($all | Group-Object threadName).Count
	[int]$tests = @($all | Group-Object @{Expression={$_.threadName -creplace '\\s+\\S+$'}}).Count
	[string]$pthreads, [string]$ptests = $threads, $tests | ForEach-Object { if ($_ -ne 1) { 's' } else { '' } }
	Write-Host ('Performance test succeeded with {0:N0} samples from {2:N0} instance{4} of {3:N0} test{5} in {1}' -f @($all).Count, ([timespan]::FromMilliseconds($ms)), $threads, $tests, $pthreads, $ptests)
}

Assert-EnvironmentVariables -Names (-split 'APP_URL IDP_USER IDP_PASSWD CHROMEDRIVER_PATH')
if ($TestDocuments -and !$DeleteSweepFolder) {
	[string]$msg = data{'The -TestDocuments option currently requires -DeleteSweepFolder, sorry!'}
	Write-Error $msg -Category NotImplemented
}

Main
