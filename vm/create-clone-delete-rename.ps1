#############
# remove-vm #
#############
$vms = "zbx-node1","zbx-node2"
get-vm $vms | select name, PowerState
$vm | Stop-VMGuest -Confirm:$False
$vm | remove-vm -DeletePermanently –Confirm:$false

##########################
##		Rename VM		##
##########################
$oldName = ''
$newName = ''
Set-VM -VM $oldName -Name $newName -Confirm:$false


##############
##	New-VM 	##
##############

#Using New-VM 
$vmName = ""
$hostName = ""
$storageName = ""
$lanName = ""
$isoPath = "[2TB VNX] ISO\Windows\Server 2012\SW_DVD9_Windows_Svr_Std_and_DataCtr_2012_R2_64Bit_English_-4_MLF_X19-82891.ISO"
$OS = "windows8Server64Guest"
$hddGB = ""
$ram = ""
$cpu = ""
$cores = ""

$vm = New-VM -Name $vmName -GuestId $OS –VMHost $hostName -Datastore $storageName -DiskGB $hddGB -MemoryGB $ram -NumCpu $cpu -PortGroup $lanName
#if necessary
	$spec=New-Object –Type VMware.Vim.VirtualMAchineConfigSpec –Property @{“NumCoresPerSocket” = $cores}
	($vm).ExtensionData.ReconfigVM_Task($spec)
$vm | New-CDDrive -IsoPath $isoPath -StartConnected:$true -Confirm:$false
#Get-VM -Name $vmName | Get-CDDrive | Set-CDDrive -IsoPath $isoPath -StartConnected:$true -Connected:$true -Confirm:$false
$vm | Start-VM  -Confirm:$false
$vm | Get-CDDrive | Set-CDDrive -NoMedia -Confirm:$false
$vm | Open-VMConsoleWindow
#https://briangordon.wordpress.com/2010/09/09/powershell-mount-iso-to-multiple-vms/

#################################
#	Get-OSCustomizationSpec		#
#################################
Get-OSCustomizationSpec 'ParsiveAxxon' -Server vcenter01.echd.ru | Get-OSCustomizationNicMapping
#https://blogs.vmware.com/PowerCLI/2014/05/working-customization-specifications-powercli-part-1.html
#https://blogs.vmware.com/PowerCLI/2014/06/working-customization-specifications-powercli-part-2.html
#https://blogs.vmware.com/PowerCLI/2014/06/working-customization-specifications-powercli-part-3.html

######################################
#	New VM from a Template (Linux)
######################################

$cl = 'VMCL51'
$template = 'CentOS7-MGT'
$vmhost = get-cluster $cl | get-vmhost | where {$_.ConnectionState -eq 'Connected'} | sort MemoryUsageGB | select -first 1
$storage = Get-DatastoreCluster -Name "$($cl)Cluster-OS"
$vmName = $vmhostname = 'test-vmcl51-migration'
$specName = "CentOS7-MGT-Specs"
$vdswitch = "Production"
$vlanId = ''
$ip = ''
$nmask = '255.255.225.0' 
$gw = ''
$date = (get-date).ToString('dd.MM.yyyy')

$PortGroupName = get-vdswitch $vdswitch | Get-VDPortGroup | Where { $_.VlanConfiguration -like "*$($vlanId)" }
$randomOSCustomName = "tempOSCustomization" + ((6564..90809) + (9774..122989) | Get-Random -Count 1)

# Get the OS CustomizationSpec and clone
$OSCusSpec = Get-OSCustomizationSpec -Name $specName | New-OSCustomizationSpec -Name $randomOSCustomName -Type NonPersistent

#Update Spec with IP information
Get-OSCustomizationNicMapping -OSCustomizationSpec $OSCusSpec |
	Set-OSCustomizationNicMapping -IPMode UseStaticIP `
	-IPAddress $ip `
	-SubnetMask $nmask `
	-DefaultGateway $gw | Out-Null

#Update Spec with hostname information	
Set-OSCustomizationSpec -OSCustomizationSpec $OSCusSpec -NamingScheme Fixed -NamingPrefix $vmhostname | Out-Null

#Get updated Spec Object
$OSCusSpec = Get-OSCustomizationSpec -Name $randomOSCustomName
Wait 5

$vm = New-VM -Template $template -Name $vmName -VMHost $vmhost -Datastore $storage -OSCustomizationSpec $OSCusSpec -Confirm:$false
Get-VM -Name $vm | Get-CDDrive | Set-CDDrive -NoMedia -Confirm:$false | Out-Null
$lan = $vm | Get-NetworkAdapter
$lan | Set-NetworkAdapter -PortGroup $PortGroupName -Confirm:$false | Out-Null
$lan | Set-NetworkAdapter -StartConnected:$true -Confirm:$false | Out-Null
Remove-OSCustomizationSpec $OSCusSpec -Confirm:$false

Set-Annotation -Entity $vm -CustomAttribute "Subsystem" -Value "01" | Out-Null
Set-Annotation -Entity $vm -CustomAttribute "Owner" -Value "MGT" | Out-Null
Set-Annotation -Entity $vm -CustomAttribute "CreationDate" -Value $date | Out-Null
Set-Annotation -Entity $vm -CustomAttribute "IP" -Value $ip | Out-Null
Set-Annotation -Entity $vm -CustomAttribute "Creator" -Value "o_lenets" | Out-Null
Set-Annotation -Entity $vm -CustomAttribute "Category" -Value "TEST" | Out-Null

########################################
###		 Clone a vm using powercli
########################################

$sourceVM = ''
$clonedVM = ''

$hostName = ''
$storageName = ''

$lanName = ''

Write-Host "Cloning $sourceVM into $clonedVM on host $hostName and storage $storageName in port group $lanName"

New-VM -Name $clonedVM -VM $sourceVM -VMHost $hostName -Datastore $storageName
Get-VM $clonedVM | Get-NetworkAdapter | Set-NetworkAdapter -StartConnected:$false -Confirm:$false
Get-VM $clonedVM | Get-NetworkAdapter | Set-NetworkAdapter -PortGroup $lanName -Confirm:$false
Start-VM -VM $clonedVM -Confirm:$false
Open-VMConsoleWindow –VM $clonedVM

Get-VM $clonedVM | Get-NetworkAdapter | Set-NetworkAdapter -StartConnected:$true -Connected:$true -Confirm:$false

##################################################
###		 Clone a vm with Customizer	(Windows) 
##################################################

$sourceVM = ''
$clonedVM = ''
$vmhostname = ''
$ip = ''
$nmask = ''
$gw = ''
$dns1 = ''
$dns2 = ''
$cl = 'InfraCL02'

$vdswitch = ''
$vlanId = ''

$date = (get-date).ToString('dd.MM.yyyy')
$specName = 'win2012'
$vmhost = get-cluster $cl | get-vmhost | where {$_.ConnectionState -eq 'Connected'} | sort MemoryUsageGB | select -first 1
$storageName = Get-DatastoreCluster -Name "InfraCL Silver"

$PortGroupName = get-vdswitch $vdswitch | Get-VDPortGroup | Where { $_.VlanConfiguration -like "*$($vlanId)" }
$randomOSCustomName = "tempOSCustomization" + ((6564..90809) + (9774..122989) | Get-Random -Count 1)

# Get the OS CustomizationSpec and clone
$OSCusSpec = Get-OSCustomizationSpec -Name $specName | New-OSCustomizationSpec -Name $randomOSCustomName -Type NonPersistent

#Update Spec with IP information
Get-OSCustomizationNicMapping -OSCustomizationSpec $OSCusSpec |
	Set-OSCustomizationNicMapping -IPMode UseStaticIP `
	-IPAddress $ip `
	-SubnetMask $nmask `
	-Dns $dns1,$dns2 `
	-DefaultGateway $gw | Out-Null

#Update Spec with hostname information	
Set-OSCustomizationSpec -OSCustomizationSpec $OSCusSpec -NamingScheme Fixed -NamingPrefix $vmhostname | Out-Null

#Get updated Spec Object
$OSCusSpec = Get-OSCustomizationSpec -Name $randomOSCustomName
Wait 5

Write-Host "Cloning $sourceVM into $clonedVM on host $vmhost and storage $storageName in port group $PortGroupName"
$vm = New-VM -Name $clonedVM -VM $sourceVM -VMHost $vmhost -Datastore $storageName -OSCustomizationSpec $OSCusSpec

Get-VM -Name $vm | Get-CDDrive | Set-CDDrive -NoMedia -Confirm:$false | Out-Null
$lan = $vm | Get-NetworkAdapter
$lan | Set-NetworkAdapter -PortGroup $PortGroupName -Confirm:$false | Out-Null
$lan | Set-NetworkAdapter -StartConnected:$true -Confirm:$false | Out-Null
Remove-OSCustomizationSpec $OSCusSpec -Confirm:$false

Set-Annotation -Entity $vm -CustomAttribute "Subsystem" -Value "01" | Out-Null
Set-Annotation -Entity $vm -CustomAttribute "Owner" -Value "AXXON" | Out-Null
Set-Annotation -Entity $vm -CustomAttribute "CreationDate" -Value $date | Out-Null
Set-Annotation -Entity $vm -CustomAttribute "IP" -Value $ip | Out-Null
Set-Annotation -Entity $vm -CustomAttribute "Creator" -Value "o_lenets" | Out-Null
Set-Annotation -Entity $vm -CustomAttribute "Category" -Value "PROD" | Out-Null

#Start-VM -VM $vm -Confirm:$false

