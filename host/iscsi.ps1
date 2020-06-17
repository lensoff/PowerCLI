################
#	Get info
################
# Get targets
$vmhost | Get-VMHostHba -Type iScsi | Get-IScsiHbaTarget | Sort Address
#$vmhost | Get-VMHostHba -Type iScsi | Get-IScsiHbaTarget -Type [Send|Static] | Sort Address
#
Get-VMHostHba -Device *hba0* | fl

#
# Get the clusters' targets
#
$targets = ForEach ($cl in Get-Cluster | sort ) {
	ForEach ($esx in $cl | get-vmhost | where { $_.Name -like "srv*" } | sort) {
		ForEach ( $target in $esx | Get-VMHostHba -Type iScsi | Get-IScsiHbaTarget | sort IScsiName ) {
			New-Object PSObject -Property @{
				Host = $esx.Name
				Cluster = $esx.Parent
				IP = $target.Address
				IQN = $target.IScsiName
				Type = $target.Type
			}
		}
	}
}
$targets | select Host,Cluster,IP,IQN,Type | Export-Csv -Path "D:\t.csv" -NoTypeInformation -UseCulture -Encoding UTF8

#
# Get the host's targets and storage system names (needed csv with ip and SAN systems names)
#
$targets = ForEach ($esx in $cl | get-vmhost | select -first 1 | where { $_.Name -like "srv*" } | sort) {	
	ForEach ( $target in $esx | Get-VMHostHba -Type iScsi | Get-IScsiHbaTarget | sort IScsiName ) {
		New-Object PSObject -Property @{
			Host = $esx.Name
			Cluster = $esx.Parent
			IP = $target.Address
			IQN = $target.IScsiName
			Type = $target.Type
			Name = $null
		}
	}
}

$csvTargets = "D:\Target-list.csv"
$targetData = import-csv $csvTargets -Delimiter ';'

ForEach ( $Entry in $targets ){
    $NameObj = $targetData | Where-Object {$_.IP -like "$($Entry.IP)"}	
    $Entry.Name = $NameObj.Name	
}
$targets | ft -auto Host,IP,Name
$targets | select Host,Cluster,IP,IQN,Type,Name	| Export-Csv -Path "D:\$($cl.Name).csv" -NoTypeInformation -UseCulture -Encoding UTF8

#########################
#	Target Operations	#
#########################

###################
#	Adding targets
###################

# Add dynamic targets
$vmhost | Get-VMHostHba -Type "iScsi" | New-IScsiHbaTarget -Address "10.200.163.69" -Type Send
# Add static targets
$vmhost | Get-VMHostHba -Type "iScsi" | New-IScsiHbaTarget -Address "10.200.163.69" -Type Static -IScsiName "iqn.1992-08.com.netapp:5600.60080e50004751500000000059fbfd61"

# using import from csv
$csvTargets = "D:\Target-list.csv"
$Filter1 = "ST08-01-b"
$Filter2 = "ST08-02-b"
$Filter3 = "ST08-03-b"
$Filter4 = $null
$Filter5 = $null
$targetData = import-csv $csvTargets -Delimiter ';' | Where {$_.Name -EQ $Filter1 -Or $_.Name -EQ $Filter2 -Or $_.Name -EQ $Filter3 -Or $_.Name -EQ $Filter4 -Or $_.Name -EQ $Filter5}
$targetData | select Name,IP,IQN
Read-Host -Prompt "Press Enter continue or close the PS window to quit" 
#Adding targets
$targetData | ForEach {
	Write-Host "Adding target" $_.IP "from Storage" $_.Name "to" -ForegroundColor "Green"
	Write-Host $hosts -ForegroundColor "Yellow"
	Get-VMHost $hosts | Get-VMHostHba -Type "iScsi" | New-IScsiHbaTarget -Address $_.IP -Type Static -IScsiName $_.IQN | Out-Null
}


###################
#	Copying targets from a neighbour
###################

$targets = $hosts | select -first 1 | where { $_ -ne $vmhost } | Get-VMHostHba -Type iScsi | Get-IScsiHbaTarget
$i = 1
$count = $targets.Count
ForEach ( $target in $targets ) {
	Write-Host $i " of " $count -ForegroundColor "Yellow"
	Write-Host "Adding target" $target.Address "to" $vmhost.Name
	$vmhost | Get-VMHostHba -Type "iScsi" | New-IScsiHbaTarget -Address $target.Address -Type Static -IScsiName $target.IScsiName #| Out-Null
	$i++
}

###################
#	Removing targets
###################

# Remove static targets
$vmhost | Get-VMHostHba -Type "iScsi" | Get-IScsiHbaTarget -Type Static | Where {$_.Address -eq "10.200.163.69"} | Remove-IScsiHbaTarget -Confirm:$false
# Remove dynamic targets
$vmhost | Get-VMHostHba -Type "iScsi" | Get-IScsiHbaTarget -Type "Send" | Where {$_.Address -eq "10.200.163.69"} | Remove-IScsiHbaTarget -Confirm:$false
# Remove all targets
$vmhost | Get-VMHostHba -Type "iScsi" | Get-IScsiHbaTarget | Remove-IScsiHbaTarget -Confirm:$false

# using import from csv
ForEach ($row in $targetData) {
	Write-Host "Removing target" $row.IP "from Storage" $row.Name "from" -ForegroundColor "Green"
	Write-Host $hosts -ForegroundColor "Yellow"
	$hosts | Get-VMHostHba -Type "iScsi" | Get-IScsiHbaTarget -Type Static | Where {$_.Address -eq $row.IP} | Remove-IScsiHbaTarget -Confirm:$false
}

#########################
#	VMHostiSCSIBinding
#########################
#
#	Import Get-VMHostiSCSIBinding.psm1 !!!!
#

get-vmhost srv18-20.echd.ru | Get-VMHostiSCSIBinding -HBA "vmhba64" | ft

#show bindings
ForEach ($cl in get-cluster | sort) {
	Write-Host $cl.Name -ForegroundColor "Green"
	Write-Host " "
	ForEach ($esx in $cl | get-vmhost | where { $_.ConnectionState -eq "Connected" -or $_.ConnectionState -eq "Maintenance" } | sort) {
		Write-Host $cl.Name "/" $esx.Name -ForegroundColor "Yellow"
		$vmhba = ($esx | Get-VMHostHba | Where {$_.Type -eq "Iscsi"} | Where {$_.Model -eq "iSCSI Software Adapter"}).Device
		Write-Host "vmhba name is" $vmhba
		$esx | Get-VMHostiSCSIBinding -HBA $vmhba | ft
		
	}
}

# show bindings existance
$table = ForEach ($cl in get-cluster | sort) {	
	ForEach ($esx in $cl | get-vmhost | where { $_.ConnectionState -eq "Connected" -or $_.ConnectionState -eq "Maintenance" } | sort) {
		$bi = $null
		Write-Host $cl.Name "/" $esx.Name -ForegroundColor "Yellow"
		$vmhba = ($esx | Get-VMHostHba | Where {$_.Type -eq "Iscsi"} | Where {$_.Model -eq "iSCSI Software Adapter"}).Device
		$bi = $esx | Get-VMHostiSCSIBinding -HBA $vmhba
		if ($bi -eq $null) { $existance = "doesnt_exist" } else { $existance = "exists" }
		New-Object PSObject -Property @{
			cl = $cl.Name
			esx = $esx.Name
			bindExist = $existance
		}
		
	}
}
$table | select cl,esx,bindExist | Export-Csv -Path "d:\elect-vcenter02-network-binding.csv" -NoTypeInformation -UseCulture -Encoding UTF8

#
#	Import Set-VMHostiSCSIBinding.psm1 !!!!
#

...

####################
#	esx cli v2
####################

#!!!!# https://www.virten.net/2016/11/how-to-use-esxcli-v2-commands-in-powercli/ 

#Setup Host networking and storage ready for ISCSI LUNs
# http://veducate.co.uk/powercli-setup-host-networking-and-storage-ready-for-iscsi-luns/

#When to use iSCSI Port Binding, and why!
# https://www.stephenwagner.com/2014/06/07/vmware-vsphere-iscsi-port-binding/

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
