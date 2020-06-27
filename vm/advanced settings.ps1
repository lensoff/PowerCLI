#Disabling the VMware Tools shrink option
#https://kb.vmware.com/s/article/1010941
New-AdvancedSetting -Entity $vm -Name isolation.tools.diskWiper.disable -Value TRUE -Confirm:$false -Force:$true
New-AdvancedSetting -Entity $vm -Name isolation.tools.diskShrink.disable -Value TRUE -Confirm:$false -Force:$true
#Copy, paste and drag'n'drop feature
#https://pubs.vmware.com/vsphere-50/index.jsp?topic=%2Fcom.vmware.vmtools.install.doc%2FGUID-685722FA-9009-439C-9142-18A9E7C592EA.html
New-AdvancedSetting -Entity $vm -Name isolation.tools.copy.disable -Value TRUE -Confirm:$false -Force:$true
New-AdvancedSetting -Entity $vm -Name isolation.tools.paste.disable -Value TRUE -Confirm:$false -Force:$true
New-AdvancedSetting -Entity $vm -Name isolation.tools.dnd.disable -Value TRUE -Confirm:$false -Force:$true
New-AdvancedSetting -Entity $vm -Name isolation.tools.setGUIOptions.enable -Value FALSE -Confirm:$false -Force:$true
#Connecting and modifying devices
New-AdvancedSetting -Entity $vm -Name isolation.device.connectable.disable -Value TRUE -Confirm:$false -Force:$true
New-AdvancedSetting -Entity $vm -Name isolation.device.edit.disable -Value TRUE -Confirm:$false -Force:$true
#Virtual Machine Communication Interface (VMCI)
New-AdvancedSetting -Entity $vm -Name vmci0.unrestricted -Value FALSE -Confirm:$false -Force:$true
#Configuring virtual machine log size
New-AdvancedSetting -Entity $vm -Name log.rotateSize -Value '1000000' -Confirm:$false -Force:$true
New-AdvancedSetting -Entity $vm -Name log.keepOld -Value '10' -Confirm:$false -Force:$true
#VMX file size
New-AdvancedSetting -Entity $vm -Name tools.setInfo.sizeLimit -Value '1048576' -Confirm:$false -Force:$true
#How to Disable Guest Operations in the VIX API
#https://kb.vmware.com/s/article/1010103
New-AdvancedSetting -Entity $vm -Name guest.commands.enabled -Value FALSE -Confirm:$false -Force:$true
#Sending performance counters into PerfMon
New-AdvancedSetting -Entity $vm -Name tools.guestlib.enableHostInfo -Value FALSE -Confirm:$false -Force:$true
#bios.bootdelay
$vmName = 'TestVM'
$vm = Get-VM -Name $vmName

$spec = New-Object VMware.Vim.VirtualMachineConfigSpec
$spec.BootOptions = New-Object VMware.Vim.VirtualMachineBootOptions
#$spec.BootOptions.EnterBIOSSetup = $true
$spec.BootOptions.BootDelay = 10000
$vm.ExtensionData.ReconfigVM($spec) 
