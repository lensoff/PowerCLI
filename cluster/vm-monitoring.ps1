#https://damiankarlson.com/2011/01/13/managing-vmware-has-vm-monitoring-powercli/
#https://communities.vmware.com/thread/288725

#Enable VM Monitoring (medium) on cluster:
$spec = New-Object VMware.Vim.ClusterConfigSpecEx
$spec.dasConfig = New-Object VMware.Vim.ClusterDasConfigInfo
$spec.dasConfig.vmMonitoring = "vmMonitoringOnly"
$spec.dasConfig.defaultVmSettings = New-Object VMware.Vim.ClusterDasVmSettings
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings = New-Object VMware.Vim.ClusterVmToolsMonitoringSettings
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.enabled = $true
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.vmMonitoring = "vmMonitoringOnly"
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.failureInterval = 60
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.minUpTime = 240
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.maxFailures = 3
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.maxFailureWindow = 86400

$cluster = Get-Cluster -Name "Cluster"
$_this = Get-View -Id $cluster.Id
$_this.ReconfigureComputeResource_Task($spec, $true)



#Disable VM Monitoring on VM:
$vm = Get-VM -Name "Name"

$spec = New-Object VMware.Vim.ClusterConfigSpecEx
$spec.dasVmConfigSpec = New-Object VMware.Vim.ClusterDasVmConfigSpec[] (1)
$spec.dasVmConfigSpec[0] = New-Object VMware.Vim.ClusterDasVmConfigSpec
$spec.dasVmConfigSpec[0].operation = "edit"
$spec.dasVmConfigSpec[0].info = New-Object VMware.Vim.ClusterDasVmConfigInfo
$spec.dasVmConfigSpec[0].info.key = New-Object VMware.Vim.ManagedObjectReference
$spec.dasVmConfigSpec[0].info.key.type = "VirtualMachine"
$spec.dasVmConfigSpec[0].info.key.value = $vm.ExtensionData.MoRef.Value
$spec.dasVmConfigSpec[0].info.dasSettings = New-Object VMware.Vim.ClusterDasVmSettings
$spec.dasVmConfigSpec[0].info.dasSettings.vmToolsMonitoringSettings = New-Object VMware.Vim.ClusterVmToolsMonitoringSettings
$spec.dasVmConfigSpec[0].info.dasSettings.vmToolsMonitoringSettings.enabled = $false
$spec.dasVmConfigSpec[0].info.dasSettings.vmToolsMonitoringSettings.vmMonitoring = "vmMonitoringDisabled"
$spec.dasVmConfigSpec[0].info.dasSettings.vmToolsMonitoringSettings.clusterSettings = $false

$_this = Get-View -Id $vm.VMHost.Parent.Id
$_this.ReconfigureComputeResource_Task($spec, $true)


#If you’re interested in setting the cluster-level VM monitoring at different levels (low, medium, high, custom), here are the settings you’ll need.

#Low:
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.failureInterval = 120
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.minUpTime = 480
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.maxFailures = 3
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.maxFailureWindow = 604800

#Medium:
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.failureInterval = 60
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.minUpTime = 240
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.maxFailures = 3
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.maxFailureWindow = 86400

#High:
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.failureInterval = 30
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.minUpTime = 120
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.maxFailures = 3
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.maxFailureWindow = 3600

#Custom: Uses the same keys as above, just with different values for failureInterval, minUpTime, maxFailures, and maxFailureWindow. maxFailureWindow is in seconds, or -1 to disable it.

#VM and App Monitoring on cluster:

$spec.dasConfig.vmMonitoring = "vmAndAppMonitoring"

#Excluding App Monitoring on a VM (enabled on cluster):

$vm = Get-VM -Name "Name"

$spec = New-Object VMware.Vim.ClusterConfigSpecEx
$spec.dasVmConfigSpec = New-Object VMware.Vim.ClusterDasVmConfigSpec[] (1)
$spec.dasVmConfigSpec[0] = New-Object VMware.Vim.ClusterDasVmConfigSpec
$spec.dasVmConfigSpec[0].operation = "add"
$spec.dasVmConfigSpec[0].info = New-Object VMware.Vim.ClusterDasVmConfigInfo
$spec.dasVmConfigSpec[0].info.key = New-Object VMware.Vim.ManagedObjectReference
$spec.dasVmConfigSpec[0].info.key.type = "VirtualMachine"
$spec.dasVmConfigSpec[0].info.key.value = $vm.ExtensionData.MoRef.Value
$spec.dasVmConfigSpec[0].info.dasSettings = New-Object VMware.Vim.ClusterDasVmSettings
$spec.dasVmConfigSpec[0].info.dasSettings.vmToolsMonitoringSettings = New-Object VMware.Vim.ClusterVmToolsMonitoringSettings
$spec.dasVmConfigSpec[0].info.dasSettings.vmToolsMonitoringSettings.enabled = $true
$spec.dasVmConfigSpec[0].info.dasSettings.vmToolsMonitoringSettings.vmMonitoring = "vmMonitoringOnly"
$spec.dasVmConfigSpec[0].info.dasSettings.vmToolsMonitoringSettings.clusterSettings = $false
$spec.dasVmConfigSpec[0].info.dasSettings.vmToolsMonitoringSettings.failureInterval = 60
$spec.dasVmConfigSpec[0].info.dasSettings.vmToolsMonitoringSettings.minUpTime = 240
$spec.dasVmConfigSpec[0].info.dasSettings.vmToolsMonitoringSettings.maxFailures = 3
$spec.dasVmConfigSpec[0].info.dasSettings.vmToolsMonitoringSettings.maxFailureWindow = 86400