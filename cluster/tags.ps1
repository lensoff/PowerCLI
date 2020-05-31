#New-TagCategory
New-TagCategory -Name "MyTagCategory" -Cardinality "Single" -EntityType "VirtualMachine"
New-TagCategory -Name "MyTagCategory" -Cardinality "Multiple" -Description "MyTagCategory description"

#New-Tag
Get-TagCategory -Name "MyTagCategory" | New-Tag -Name "MyTag" -Description "Create MyTag tag in MyTagCategory category."

#New-TagAssignment
$myTag = Get-Tag MyTag
$myVM = Get-VM ‘*myvm*’
New-TagAssignment -Tag $myTag -Entity $myVM

#Get-Tag
Get-Tag -Name MyTag

#Get-TagAssignment
Get-TagAssignment -Entity $datastore -Category MyCategory

#Remove-TagAssignment
$myTagAssignment = Get-TagAssignment $myVM
Remove-TagAssignment $myTagAssignment

get-vm -tag '01' | Get-TagAssignment
get-VM | Get-TagAssignment | ft Entity,Tag
Get-Cluster "DMZ" | Get-VM | where{$_.Guest.OSFullName -match "Windows"} | Get-TagAssignment | where{$_.Tag.Name -like '1_Tt_le_tps*' -and $_.Tag.Name -like 'criticite_moyenne*' } | Select @{N='VM';E={$_.Entity.Name}}
Get-VM | where {(Get-TagAssignment -Entity $_ | Select -ExpandProperty Tag) -like 'Backups*'}

get-tagcategory SubSystem | get-tag | ForEach {
	Write-host "tag is" $_.Name "with Description" $_.Description -ForegroundColor "Green"
	$a = Get-VM -Tag $_
	Write-host "Associated vms are"  -ForegroundColor "Yellow"
	Write-host $a
}


#https://blogs.vmware.com/PowerCLI/2013/12/using-tags-with-powercli.html

Get-VM | where {(Get-TagAssignment -Entity $_ | Select -ExpandProperty Tag) -like 'Backups*'}

#############################
#		MGMT vCenter		#
#############################
New-TagCategory -Name "Owner" -Cardinality "Single" -EntityType "VirtualMachine"
New-TagCategory -Name "SubSystem" -Cardinality "Multiple" -EntityType "VirtualMachine"
New-TagCategory -Name "Creator" -Cardinality "Single" -EntityType "VirtualMachine"
New-TagCategory -Name "Category" -Cardinality "Single" -EntityType "VirtualMachine"

Get-TagCategory -Name "Owner" | New-Tag -Name "MGT" -Description "MGT machines"
Get-TagCategory -Name "Owner" | New-Tag -Name "DEPO" -Description "DEPO machines"
Get-TagCategory -Name "Owner" | New-Tag -Name "VMware" -Description "VMware machines"
Get-TagCategory -Name "SubSystem" | New-Tag -Name "01" -Description "Infrastructure Service"
Get-TagCategory -Name "SubSystem" | New-Tag -Name "02" -Description "Monitoring Service"
Get-TagCategory -Name "SubSystem" | New-Tag -Name "05" -Description "Virtualization Service"
Get-TagCategory -Name "Creator" | New-Tag -Name "Lenets" -Description "Lenets machines"
Get-TagCategory -Name "Creator" | New-Tag -Name "Dolgov" -Description "Dolgov machines"
Get-TagCategory -Name "Creator" | New-Tag -Name "Konyshev" -Description "Konyshev machines"
Get-TagCategory -Name "Creator" | New-Tag -Name "Smirnov" -Description "Smirnov machines"
Get-TagCategory -Name "Creator" | New-Tag -Name "System" -Description "Machines with unknown creator"
Get-TagCategory -Name "Category" | New-Tag -Name "PROD" -Description "MGT machines"
Get-TagCategory -Name "Category" | New-Tag -Name "TEST" -Description "Netris machines"

#Category
get-vm | New-TagAssignment -Tag PROD
#Creator
get-vm *zbx* | New-TagAssignment -Tag 'Lenets'
get-vm Zkur | New-TagAssignment -Tag 'Dolgov'
get-vm | where {$_.name -notlike '*zbx*' -and $_.name -ne 'Zkur'} | New-TagAssignment -Tag 'System'
#owner
$vm = "CyberArk-PSM","CyberArk-PSMP","CyberArk-PTA","CyberArk-PVWA-CPM","CyberArk-Vault-1","CyberArk-Vault-2","zbx-ma-node1","zbx-ma-node2","zbx-my-node1","zbx-my-node2","zbx-my-node3","zbx-node1","zbx-node2","zbx-proxy-kur-node1","zbx-proxy-kur-node2","Zkur"
get-vm $vm | New-TagAssignment -Tag MGT
$vm = "loginsight01","mgmtvcenter01","psc01","tstvcsa01","umds01","vcenter01","vrops01"
get-vm $vm | New-TagAssignment -Tag VMware
$vm = "dozor02","dozor03","mellanox_neo01"
get-vm $vm | New-TagAssignment -Tag DEPO
#Subsystem
$vm = "CyberArk-PSM","CyberArk-PSMP","CyberArk-PTA","CyberArk-PVWA-CPM","CyberArk-Vault-1","CyberArk-Vault-2","loginsight01","mellanox_neo01"
get-vm $vm | New-TagAssignment -Tag '01'
$vm = "dozor02","dozor03","vrops01","zbx-ma-node1","zbx-ma-node2","zbx-my-node1","zbx-my-node2","zbx-my-node3","zbx-node1","zbx-node2","Zkur"
get-vm $vm | New-TagAssignment -Tag '02'
$vm = "mgmtvcenter01","psc01","tstvcsa01","umds01","vcenter01"
get-vm $vm | New-TagAssignment -Tag '05'


