##################################################
##	How to add, remove and extend VM’s disk		##
##################################################

###########
#	Add
###########
$vm | New-HardDisk -CapacityGB 10

#################################
#	Add on different datastore
#################################
#$format = thin|thick|EagerZeroedThick
$vm | New-HardDisk -CapacityGB $size -Datastore $datastore #-StorageFormat $format
#Example
get-vm 5807* | new-harddisk -CapacityGB 10 -Datastore (Get-DatastoreCluster 'VMCL58Cluster-Data')

###############
#	Remove
###############
Get-HardDisk -VM $vm | Where-Object {$_.Filename -like "*MyVM_4*"} | Remove-HardDisk

##############
#	Expand
##############
Get-HardDisk -vm $vmName | Where {$_.Name -eq "Hard disk 1"} | Set-HardDisk -CapacityGB 150 -Confirm:$false

######################
#	Collecting info
######################
Get-HardDisk $vm
$vm | Get-HardDisk | select name,Filename,CapacityGB
ForEach ( $hdd in $vm | get-harddisk | sort ) { 
	Write-Host $hdd.Filename.Split('\[')[1].Split('\]')[0]
}
(get-vm | Get-HardDisk | measure-Object CapacityGB -Sum).sum
Get-VM | Select-Object Name,@{n="HardDiskSizeGB"; e={(Get-HardDisk -VM $_ | Measure-Object -Sum CapacityGB).Sum}}


###########################
#	VM capacity Report
###########################
$path = ""
$table = ForEach ( $cl in get-cluster VMCL* | sort ) {
	ForEach ( $vm in $cl | get-vm | sort ) {
		$cap = ( $vm | Get-HardDisk | measure-Object CapacityGB -Sum ).sum
			New-Object PSObject -Property @{
				cl = $cl.Name
				vm = $vm.Name
				capacity = $cap
			}
		}
}	
$table | select cl,vm,capacity | Export-Csv -Path $path -NoTypeInformation -UseCulture -Encoding UTF8
