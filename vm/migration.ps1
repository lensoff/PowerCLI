######################################
##	Migrate VM	to another storage	##
######################################
# I
Get-VM $vm | Move-VM -Datastore ''
# II
$dsOrig = get-datastore ""
$dsNew = get-datastore ""
$dsOrig | get-vm | move-vm -Datastore $dsNew -RunAsync
Get-Task
# III
$vms = $dsOrig | get-vm | sort
ForEach ( $vm in $vms ) {
	Write-Host $vm.Name
	Get-VM $vm | Get-HardDisk | where {$_.Filename -match "$($dsOrig)"} | Move-HardDisk -Datastore $dsNew -Confirm:$false | Out-Null
}

##########################
##	Migrate vmx file	##
##########################
$vm | select Name,@{E={$_.ExtensionData.Config.Files.VmPathName};L="VM Path"}


$tgtConfigDS = "InfraCL-ST01-01-L101-s"
$hds = Get-HardDisk -VM $vm

$spec = New-Object VMware.Vim.VirtualMachineRelocateSpec 
$spec.datastore = (Get-Datastore -Name $tgtConfigDS).Extensiondata.MoRef
$hds | %{
    $disk = New-Object VMware.Vim.VirtualMachineRelocateSpecDiskLocator
    $disk.diskId = $_.Extensiondata.Key
    $disk.datastore = $_.Extensiondata.Backing.Datastore
    $spec.disk += $disk
}

$vm.Extensiondata.RelocateVM_Task($spec, "defaultPriority") | Out-Null

##########################################
##	Migrate template to another storage	##
##########################################
# I
$vmTemplate = $vm = ''
$dsNew = ''
Get-Template $vmTemplate | Set-Template -ToVM
get-vm $vmTemplate | move-vm -Datastore $dsNew -RunAsync
Get-VM $vm | Set-VM -ToTemplate -Name $vmTemplate -Confirm:$false
# II
$dsOrig = ""
$dsNew = ""
get-datastore $dsOrig | get-template | ForEach {
	$vmTemplate = $vm = $_.Name	
	$vm = Get-Template $vmTemplate | Set-Template -ToVM
	$vm | move-vm -Datastore $dsNew -RunAsync
	Do {
		Start-Sleep 15
		$ds = (get-vm $vm | get-datastore).Name
	}
	While ($ds -ne $dsNew)
	$vm | Set-VM -ToTemplate -Confirm:$false
}

#####################################################
##	Migrate VM	to another cluster and port group with shutdown
#####################################################

#https://blogs.vmware.com/PowerCLI/2017/01/spotlight-move-vm-cmdlet.html

$vm = ''
#$vmHost = (Get-VM $vm).VMHost
#$clName = (Get-VMHost $vmHost).Parent
#$datastore = (get-vm $vm | Get-Datastore).name
#$lanName = (get-vm $vm | get-networkadapter).NetworkName
$lanAdapter = (get-vm $vm | get-networkadapter).Name
Get-VM -Name $vm | Get-CDDrive | Set-CDDrive -NoMedia -Confirm:$false
Get-VM -Name $vm | Get-FloppyDrive | Set-FloppyDrive -NoMedia -Confirm:$false
get-networkadapter -vm $vm -name $lanAdapter |
	set-networkadapter -networkname 'VM Network' -connected:$false -confirm:$false
Stop-VMGuest $vm -Confirm:$False	

$lanName2 = Get-VDPortGroup | where-object {$_.VlanConfiguration -like '*501'}
#$clName2 = Get-VDPortGroup -Name $lanName2 | Get-VM | Get-VMHost | Get-Cluster
$clName2 = Get-Cluster InfraCL01
$vmHost2 = Get-Cluster -Name $clName2 | Get-VMHost | Sort-Object MemoryUsageGB | Select-Object -First 1
$datastore2 = get-vm z32 | Get-VMHost | Get-Datastore | Sort-Object CapacityGB -Descending | Select-Object -First 1

Write-Host "$clName2"
Write-Host "$vmHost2"
Write-Host "$datastore2"
Write-Host "$lanName2"

move-vm -vm $vm -destination $vmHost2 -datastore $datastore2 -Confirm:$false

get-vm -name $vm |
	get-networkadapter -name $lanAdapter |
	set-networkadapter -StartConnected:$true -confirm:$false |
	set-networkadapter -portgroup $lanName2 -confirm:$false

Start-VM $vm -Confirm:$False
	
