#####################################
#	Locate VMs with Multi-Writer
#####################################

$array = @()
$vms = get-cluster "ClusterName" | get-vm
foreach ($vm in $vms){
	$disks = get-advancedsetting -Entity $vm | ? { $_.Value -like вЂњ*multi-writer*вЂќ  }
	foreach ($disk in $disks){
		$REPORT = New-Object -TypeName PSObject
		$REPORT | Add-Member -type NoteProperty -name Name -Value $vm.Name
		$REPORT | Add-Member -type NoteProperty -name VMHost -Value $vm.Host
		$REPORT | Add-Member -type NoteProperty -name Mode -Value $disk.Name
		$REPORT | Add-Member -type NoteProperty -name Type -Value вЂњMultiWriterвЂќ
		$array += $REPORT
	}
}
$array | out-gridview

############################################
#	Configure vms with multi-writer
############################################
$SizeGB = 1
$sourceVM = Get-VM 'server1'
$shareWith = @('server2', 'server3')
$disk = New-HardDisk -VM $sourceVM -CapacityGB $SizeGB -Persistence persistent -StorageFormat EagerZeroedThick
$disk | New-ScsiController -Type VirtualLsiLogicSAS -BusSharingMode Phisycal
foreach ($targetVM in $shareWith) {
    $targetVM = Get-VM $targetVM
    New-HardDisk -VM $targetVM -DiskPath $disk.Filename | New-ScsiController -Type VirtualLsiLogicSAS -BusSharingMode Virtual
}

#############################################
#	Change Persistence mode (on the fly)	#
#############################################
Get-VM | % { Get-HardDisk -VM $_ | Where {$_.Persistence -eq "IndependentPersistent"} }
Get-VM | % { Get-HardDisk -VM $_ | Where {$_.Persistence -eq "IndependentPersistent"} | % {Set-HardDisk -HardDisk $_ -Persistence "Persistent" -Confirm:$false} }

#############
#	Links
#############

#https://blog.jgriffiths.org/powercli-locate-vms-with-multiwriter/
#https://code.vmware.com/forums/2530/vsphere-powercli#577389
#https://www.virtuallyghetto.com/2015/10/new-method-of-enabling-multiwriter-vmdk-flag-in-vsphere-6-0-update-1.html
#https://github.com/lamw/vghetto-scripts/blob/master/powershell/configureMultiwriterVMDKFlag.ps1
#https://github.com/lamw/vghetto-scripts/blob/master/powershell/addMultiwriterVMDK.ps1

#Multi-Write GUI
#https://theitbros.com/share-disk-between-vms-on-vmware-esxi/

#https://communities.vmware.com/thread/491901

#https://serverfault.com/questions/304212/powercli-add-shared-hard-disk-to-vm-using-existing-scsi-controller

#https://docs.vmware.com/en/VMware-vSphere/6.5/vsphere-esxi-vcenter-server-651-setup-mscs.pdf

#https://ict-freak.nl/2009/12/01/powercli-change-persistence-mode-on-the-fly/
