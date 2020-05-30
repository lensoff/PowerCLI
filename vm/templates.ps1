#################
#	Info
#################
get-template *CentOS* | select Name,@{N='Server';E={$_.Uid.Split('@')[1].Split(':')[0]}}

################
#	remove
################
get-template *CentOS*MGT -Server tstvcenter01.echd.ru | remove-template -DeletePermanently –Confirm:$false
################################
#	Template to VM and back
################################
$vmTemplate = 'CentOS7-MGT'
Get-Template $vmTemplate | Set-Template -ToVM
Get-vm -Name $vmTemplate | Get-ScsiController | Set-ScsiController -Type ParaVirtual
get-vm $vmTemplate | Set-VM -ToTemplate -Confirm:$false

####################################
#	Convert the VM to a template
####################################
$vm = ''
$vmTemplate = ''
$template = Get-VM $vm | Set-VM -ToTemplate -Name $vmTemplate -Confirm:$false
