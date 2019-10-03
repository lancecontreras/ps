<#
.SYNOPSIS
    .
.DESCRIPTION
    .
.PARAMETER Path
    The path to the .
.PARAMETER LiteralPath
    Specifies a path to one or more locations. Unlike Path, the value of 
    LiteralPath is used exactly as it is typed. No characters are interpreted 
    as wildcards. If the path includes escape characters, enclose it in single
    quotation marks. Single quotation marks tell Windows PowerShell not to 
    interpret any characters as escape sequences.
#>
## Specify the timeframe you'd like to search between
Param(
	[string]$ComputerName = $env:computername ## Name of the computer. 
	, [string]$OutputPath = ''  ## Specify an output path / file where the output will be written to. If blank, output will be written in the console. 
	, [string]$SkipLogs = 'Windows PowerShell, Security, Windows Azure, Windows Assesment Console, ' ## Logs that will not be included in the search. 
	, [string]$LogName = '' ## Search on a specific log name (i.e. Application)
	, [string]$Source = '' ## Source of the event, whatever is in the source column of the event log. 
	, [int]$MaxLogs = 1000 ## Number of maximum log items to search on every LogName. 
	, [int]$Age = 24 ## Filter the age of the logs by hour. By default it's 24 hours.  
	, [switch]$help = $false 
	, [string]$Search ## The string to search for. You can use wild card (*).
)

if($help) {
	Get-Help ./Search-Events.ps1 -full
	return
}
$SearchString = $Search
$ComputerName = $env:computername
$StartTimeStamp = [datetime] $StartDate = (Get-Date).AddHours(-1 * $Age).ToString('MM-dd-yyyy HH:mm:ss')
$EndTimeStamp = [datetime] $EndDate =  (Get-Date).ToString('MM-dd-yyyy HH:mm:ss')
Write-Host "$Age hour/s"
Write-Host "From $StartTimeStamp to $EndTimeStamp"
Write-Host "MaxLogs: $MaxLogs"
Write-Host "SearchString: $SearchString"
Write-Host "Skipping: $SkipLogs"
Write-Host "LogName: $LogName"
Write-Host "Output Path: $OutputPath" 
Write-Host "Computer Name: $ComputerName"
Write-Host "Event Source: $Source"

## Specify in a comma-delimited format which event logs to skip (if any)
$SkipEventLog = $SkipLogs

## The output file path of the text file that contains all matching events
$OutputFilePath = $OutputPath

## Create the Where filter ahead of time to only get events within the timeframe
$wildcard = '*' + $SearchString + '*'
$srcWildcard = '*' + $Source + '*'
$filter = {($_.TimeCreated -ge $StartTimeStamp) -and ($_.TimeCreated -le $EndTimeStamp) -and $_.Message -like $wildcard -and $_.ProviderName -like $srcWildcard} 

foreach ($c in $ComputerName) {
	if($LogName -eq '') {
		$op_logs = Get-WinEvent -ListLog * -ComputerName $c | Where {$_.RecordCount -and !($SkipEventLog -like '*' + $_.LogName + '*')}
	} 
	else {
		$op_logs = Get-WinEvent -ListLog * -ComputerName $c | Where {$_.RecordCount -and ($LogName -eq $_.LogName)}
	}

    ## Process each event log and write each event to a text file
    $i = 0
    foreach ($op_log in $op_logs) {
		Try {		
        	Write-Progress -Activity "Processing event logs" -status "Processing $($op_log.LogName)" -percentComplete ($i / $op_logs.count*100)
			if($OutputPath -eq '') {
				Get-WinEvent $op_log.LogName -ComputerName $c -MaxEvents $MaxLogs | Where $filter | 
					Select @{n='Time';e={$_.TimeCreated}},
						@{n='Source';e={$_.ProviderName}},
						@{n='EventId';e={$_.Id}},
						@{n='Message';e={$_.Message}},
						@{n='EventLog';e={$_.LogName}} 
			} else {
				Get-WinEvent $op_log.LogName -ComputerName $c -MaxEvents $MaxLogs | Where $filter | 
					Select @{n='Time';e={$_.TimeCreated}},
						@{n='Source';e={$_.ProviderName}},
						@{n='EventId';e={$_.Id}},
						@{n='Message';e={$_.Message}},
						@{n='EventLog';e={$_.LogName}} | 
					Out-File -FilePath $OutputPath -Append -Force
			}
        	$i++
		}
		Catch{

		}
	}
}
