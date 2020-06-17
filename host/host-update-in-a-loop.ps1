$clName = "_spare"
Write-Host "=============================================" -ForegroundColor "Green"
Write-Host "        Starting loop for cluster" $clName -ForegroundColor "Green"
Write-Host "=============================================" -ForegroundColor "Green"
Write-Host ""
$cl = get-cluster $clName
Write-Host "Cluster" $cl -ForegroundColor "Yellow"
Write-Host ""
$hostsList = $cl | Get-VMHost | Where { $_.Build -eq "6921384" } | sort
Write-Host "Hosts" $hostsList -ForegroundColor "Yellow"
Write-Host ""
$lim = ($hostsList | Measure-Object | Select-Object Count).Count
Write-Host "Hosts' Quantity" $lim
Write-Host ""
$lim -= 1
Write-Host "Loops' Quantity" $lim
Write-Host ""

$var = 0
$select = 1
DO
{
	$skip = $select*$var
	$hosts = $hostsList | Select-Object -Skip $skip | select -first $select
	Write-Host "Starting Loop $var" -ForegroundColor "Green"
	Write-Host "Updating hosts are:" -ForegroundColor "Yellow"
	write-host $hosts
	
	Start-Sleep 60
	
	#Read-Host -Prompt "Press any key to continue or CTRL+C to quit" 
	
	if ( (Get-VMHost $hosts).ConnectionState -eq "Connected" ){ $state = $true } else {$state = $false}
	if 	( $state -eq $true ) {
		Write-Host "Entering Maintenance Mode" -ForegroundColor Yellow
		#put the ESXi host VMHost-1 into maintenance mod
		$hosts | Set-VMHost -State Maintenance
	}
	Write-Host "Installing updates" -ForegroundColor Yellow
	#place the critical host baseline into the $Baseline variable for use in future commands
	#$Baseline = Get-Baseline -Name 'Critical Host Patches (Predefined)'
	$Baseline = Get-Baseline -Name 'host_typical'
	#ensure the baseline is attached to host
	$hosts | Add-EntityBaseline -Baseline $Baseline
	#or
	$hosts | Attach-Baseline -Baseline $Baseline
	#test whether the host is in compliance
	$hosts | Test-Compliance #-UpdateType HostPatch -Verbose
	$hosts | Get-Compliance -Baseline $Baseline #-ComplianceStatus NotCompliant
	#stage the patches to the host
	$hosts | Copy-Patch -Confirm:$false
	#deploy the patch to my hosts
	$hosts | Update-Entity -Baseline $baseline -RunAsync -Confirm:$False
	
	$time = (Get-Date).ToString('HH:mm:ss')
	Write-Host "Starting 5 min sleep at" $time -ForegroundColor Yellow
	Start-Sleep 300
	Write-Host "Starting loop to understand if $hosts is online" -ForegroundColor Yellow
	$end = "no"	
	Do {
		Start-Sleep 5
		$aa = get-vmhost $hosts
		$timeOnline = (Get-Date).ToString('HH:mm:ss')
		if($aa[0].ConnectionState -eq "Maintenance"){
		Write-Host "$hosts is online at $timeOnline" -ForegroundColor "Yellow"
		#Send-MailMessage -From $sourceAddress -To $recipients -Subject "$hosts is online at $timeOnline"
		$end ="yes"
		}		
	}
	Until ($end -eq "yes")
	
	if 	( $state -eq $true ) {
		Write-Host "Exiting Maintenance Mode" -ForegroundColor Yellow
		$hosts | set-vmhost -State Connected
	}
	Write-Host "Suppress Hyperthread Warning" -ForegroundColor Yellow
	$hosts | Get-AdvancedSetting UserVars.SuppressHyperthreadWarning | Set-AdvancedSetting -Value 1 -Confirm:$false
	
	$var++	
} While ($var -le $lim)

