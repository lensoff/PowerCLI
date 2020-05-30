#################################
#		Start or Stop VM		#
#################################
$vms = "",""
Get-VM $vms | Start-VM -Confirm:$false
Get-VM $vms | Stop-VMGuest -Confirm:$false
Get-VM $vms | Stop-VM -Confirm:$false

#############################
#	Open-VMConsoleWindow	#
#############################
Get-VM zbx-node1 | Open-VMConsoleWindow
Open-VMConsoleWindow –VM 'zbx-proxy1'

#################
#	VM Tools	#
#################
$vm | % { get-view $_.id } | select name, @{Name="ToolsVersion"; Expression={$_.config.tools.toolsversion}}, @{ Name="ToolStatus"; Expression={$_.Guest.ToolsVersionStatus}} | Sort-Object Name
$vm | % { get-view $_.id } | Where-Object {$_.Guest.ToolsVersionStatus -like "guestToolsNeedUpgrade"} |select name, @{Name=“ToolsVersion”; Expression={$_.config.tools.toolsversion}}, @{ Name=“ToolStatus”; Expression={$_.Guest.ToolsVersionStatus}}| Sort-Object Name
Get-VM -Name $vmName | Update-Tools -NoReboot –RunAsync
Get-VM -Name $vmName | Mount-Tools
# https://blogs.vmware.com/vsphere/2018/09/automating-upgrade-of-vmware-tools-and-vmware-compatibility.html

##########################################
##	Upgrades the memory and CPU count	##
##########################################
Get-VM -Location ResourcePool01 | Set-VM -MemoryGB 2 -NumCPU 2

#############################
#	Upgrade vm hardware		#
#############################
$vm | select Name,Version
Set-Vm -VM (Get-VM -Name [VM-NAME]) -Version v[HW-VERSION]
# 8 - 5.0
# 9 - 5.1
# 10 - 5.5
# 11 - 6.0
# 13 - 6.5
# 14 - 6.7
#https://kb.vmware.com/s/article/1003746
$vm | Set-Vm -Version v10 -Confirm:$False

######################
##	ScsiController	##
######################
#Get-VM -Name $vmName | Get-ScsiController
Get-VM -Name $vmName | Get-ScsiController | Set-ScsiController -Type VirtualLsiLogicSAS|ParaVirtual

##################################
#	How to change Guest OS type
##################################
$vm = 'zbx-proxy-niz-node2'
$guestId = 'centos64Guest' | 'debian10_64Guest'
get-vm $vm | select GuestId
Stop-VMGuest $vm -Confirm:$False
Get-VM -Name $vm | Set-VM -GuestId $guestId -Confirm:$false
#optional
	get-VM $vm | Get-Networkadapter | Set-Networkadapter -type vmxnet3 -Confirm:$false
Start-VM $vm -Confirm:$False

#########################
#	Move to a folder	#
#########################
$vm = Get-VM ***
$folder = Get-Folder -Name $key -Type VM
Move-VM -VM $vm -Destination $vm.VMHost -InventoryLocation $folder

$cl = 
$folder = Get-Folder -Name $cl -Type VM
Get-Cluster $cl | get-vm | sort | % {
	Write-Host "Moving" $_.Name "to the folder" $folder.Name
	Move-VM -VM $_ -Destination $_.VMHost -InventoryLocation $folder | Out-Null
}

#########################
#	VMSwapfilePolicy	#
#########################
get-vm "zbx*" | Select Name,VMSwapfilePolicy
#Set-VM | Set-VMHost | Set-Cluster -VMSwapfilePolicy InHostDatastore -VMSwapfileDatastoreID
Get-Cluster -name "Dragons Nest" | Set-Cluster -VMSwapfilePolicy InHostDatastore
Get-Cluster -name "Dragons Nest" | Get-VMHost | Set-VMHost -VMSwapfileDatastore “*local*”
#https://vbrownbag.com/2012/05/powercli-101-changing-the-vm-swapfile-location/
#http://www.vnoob.com/2013/09/powercli-and-vm-swap-file-policy/

#############
#	Notes	#
#############
#CSV:
VMName,Note
VM1,Domain Controller
VM2,Database Server

Import-Csv "D:\Docs\VMware\vm.attr.csv" | % { Set-VM $_.VMName -Description $_.Note -Confirm:$false}
$vm | Set-VM -Description "Huawei System Reporter" -Confirm:$false

#########################
#	Custom Attribute	#
#########################

New-CustomAttribute -Name "" -TargetType VirtualMachine

Get-VM | sort | Get-Annotation -CustomAttribute "" | ft -autosize
$VM.CustomFields.Item("TestAttribute")

Set-Annotation -Entity $vm -CustomAttribute "" -Value ""

$folder = ""
$vms = Get-Folder –Name $folder | Get-VM
foreach($vm in $vms){
	Set-Annotation -Entity $vm -CustomAttribute "Subsystem" -Value "02"
	Set-Annotation -Entity $vm -CustomAttribute "Owner" -Value ""
	Set-Annotation -Entity $vm -CustomAttribute "CreationDate" -Value "01.04.2020"
	$ip = (Get-VM -Name $vm).Guest.IPAddress | Select-Object -First 1
	Set-Annotation -Entity $vm -CustomAttribute "IP" -Value $ip
	Set-Annotation -Entity $vm -CustomAttribute "Creator" -Value ""
	Set-Annotation -Entity $vm -CustomAttribute "Category" -Value "PROD"
}

$csv = "D:\temp.csv"
$Data = import-csv $csv -Delimiter ';'
$Data | ft -auto
$creator = $global:defaultVIServers.User.Split("\")[1]
ForEach ($row in $Data) {
	Set-Annotation -Entity $row.Name -CustomAttribute "Subsystem" -Value $row.Subsystem
	Set-Annotation -Entity $row.Name -CustomAttribute "Owner" -Value $row.Owner
	Set-Annotation -Entity $row.Name -CustomAttribute "CreationDate" -Value $((Get-Date).ToString('dd.MM.yyyy'))
	$ip = (Get-VM -Name $row.Name).Guest.IPAddress | Select-Object -First 1
	Set-Annotation -Entity $row.Name -CustomAttribute "IP" -Value $ip
	Set-Annotation -Entity $row.Name -CustomAttribute "Creator" -Value $creator
	Set-Annotation -Entity $row.Name -CustomAttribute "Category" -Value $row.Category
}
