#Notes: Enabling CPU Hotadd disables vNUMA. So enable enable this if its really neccessary in your environment.

Enable-MemCPUHotAdd $vm
Disable-MemCPUHotAdd $vm

#6.7
#Enable Memory and CPU HotAdd
Function Enable-MemCPUHotAdd {
	$VM = Get-VM $args[0]
	$spec = New-Object VMware.Vim.VirtualMachineConfigSpec
	$spec.memoryHotAddEnabled = $true
	$spec.cpuHotAddEnabled = $true
	$VM.ExtensionData.ReconfigVM_Task($spec)
}
#Disable Memory and CPU HotAdd

Function Disable-MemCPUHotAdd {
	$VM = Get-VM $args[0]
	$spec = New-Object VMware.Vim.VirtualMachineConfigSpec
	$spec.memoryHotAddEnabled = $false
	$spec.cpuHotAddEnabled = $false
	$VM.ExtensionData.ReconfigVM_Task($spec)
}


#http://davidstamen.com/2015/01/14/powercli-enable-cpu-and-memory-hotadd/
#https://www.altaro.com/vmware/vmware-hot-add/
