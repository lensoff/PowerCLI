Connect-VIServer vc.virten.lab -User "admin" -Password "vmware"
$esxcli = Get-EsxCli -VMhost esx1.virten.lab -V2

$esxcli.network.nic.list.Invoke()


#https://www.virten.net/2016/11/how-to-use-esxcli-v2-commands-in-powercli/
##########
#	I
##########
$esxcli = Get-EsxCli -VMHost $esx -V2
$CArgs = $esxcli.system.module.parameters.set.CreateArgs()
$CArgs.module = 'nmlx4_en'
$CArgs.parameterstring = 'tx_ring_size=4096'
$esxcli.system.module.parameters.set.Invoke($CArgs)

$esxcli.system.module.parameters.list.Invoke(@{module = 'nmlx4_en'}) | where { $_.Name -eq "tx_ring_size" } | ft -auto Name,Value

$table = ForEach ( $cl in Get-Cluster | sort ) {	
	ForEach ($esx in $cl | get-vmhost | sort) {
		Write-Host $esx.Name
		$esxcli = Get-EsxCli -VMHost $esx -V2
		New-Object PSObject -Property @{
			cl = $cl.Name
			esx = $esx.Name
			txRingSize = ($esxcli.system.module.parameters.list.Invoke(@{module = 'nmlx4_en'}) | where { $_.Name -eq "tx_ring_size" }).Value
		}
	}
}
$table | select cl,esx,txRingSize | Export-Csv -Path "D:\Report-Kur-txRingSize.csv" -NoTypeInformation -UseCulture -Encoding UTF8

##########
#	II
##########

$esxcli = Get-EsxCli -VMHost $esx -V2
$bi = $esxcli.iscsi.networkportal.list.Invoke()
$bi | % {
	$CArgs = $esxcli.iscsi.networkportal.remove.CreateArgs()
	$CArgs.adapter = $_.adapter
	$CArgs.nic =  $_.vmknic
	$CArgs.force = $true
	$esxcli.iscsi.networkportal.remove.Invoke($CArgs)
}

###

$esxcli.iscsi.networkportal.remove.invoke(@{adapter = 'vmhba64'; nic = 'vmk11'})

###

$CArgs = $esxcli.iscsi.networkportal.remove.CreateArgs()
$CArgs.adapter = 'vmhba64'
$CArgs.nic =  'vmk12'
$CArgs.force = $true
$esxcli.iscsi.networkportal.remove.Invoke($CArgs)

###

$esxcli.iscsi.networkportal.remove.CreateArgs()
$iScsi = @{
	force = $false
	nic = $iSCSInic
	adapter = $HBANumber
}
$esxcli.iscsi.networkportal.add.Invoke($iScsi) 

#############
#	III
#############
$table = ForEach ( $cl in Get-Cluster | sort ) {	
	ForEach ($esx in $cl | get-vmhost | sort) {
		Write-Host $esx.Name
		$esxcli = Get-EsxCli -VMHost $esx -V2
		$esxcli.network.nic.list.invoke() | % {
			New-Object PSObject -Property @{
				cl = $cl.Name
				esx = $esx.Name
				adapter = $_.Name
				speed = $_.Speed
				duplex = $_.Duplex
				linkStatus = $_.LinkStatus
			}
		}
	}
}
$table | select cl,esx,adapter,speed,duplex,linkStatus | Export-Csv -Path "D:\Report-Kur-netAdapters.csv" -NoTypeInformation -UseCulture -Encoding UTF8
#
$a = $esxcli.network.nic.set.CreateArgs()
$a.nicname = 'vmnic1000302'
$a.auto = $true

$a = $esxcli.network.nic.set.CreateArgs()
$a.nicname = 'vmnic1000302'
$a.speed = 10000
$a.duplex = 'full'

$esxcli.network.nic.set.invoke($a)

$esxcli.network.nic.list.invoke() | where { $_.Name -eq "vmnic0" -or $_.Name -eq "vmnic1" } | % {
	$CArgs = $esxcli.network.nic.set.CreateArgs()
	$CArgs.nicname = $_.Name
	$CArgs.auto = $true
	$esxcli.network.nic.set.invoke($CArgs)	
}
$esxcli.network.nic.list.invoke() | where { $_.Name -ne "vmnic0" -and $_.Name -ne "vmnic1" } | % {
	$CArgs = $esxcli.network.nic.set.CreateArgs()
	$CArgs.nicname = $_.Name
	$CArgs.speed = 10000
	$CArgs.duplex = 'full'
	$esxcli.network.nic.set.invoke($CArgs)
}