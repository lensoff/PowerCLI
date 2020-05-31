################
#	Connect
################
Connect-VIServer -Server <vcenter-name> | Out-Null
#or
Connect-VIServer -Server <vcenter-name-1> -User "" -Password "" | Out-Null
Connect-VIServer -Server <vcenter-name-2> -User "" -Password "" | Out-Null

#########################
#	Current conections
#########################
$global:defaultVIServers

###########################
#	Disconnect from all
###########################
Disconnect-VIServer "*" -Confirm:$false

##########################################################
#	Multi vcenter enviroment. Specifying one only
##########################################################
get-vm -Server vcenter01.echd.ru

#################
#	Frequent operations after connect
#################

$cl = Get-Cluster ""
$hosts = $cl | Get-VMHost | where { $_.ConnectionState -eq "Connected" -or $_.ConnectionState -eq "Maintenance" } | sort
$vmhost = $hosts | select -first 1
$i = 1
ForEach ( $esx in $hosts ) {
	Write-Host $i "of" $hosts.Count -ForegroundColor "Yellow"
	Write-Host $esx.Name
	Write-Host ""
	$esx | Get-VMHostStorage -RescanAllHba -RescanVmfs | Out-Null
	$i++
}
