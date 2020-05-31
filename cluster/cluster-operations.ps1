###############################
#	Show Heartbeat Datastore
###############################
$Cluster = Get-Cluster -Name Cluster_Name
$cluster.ExtensionData.RetrieveDasAdvancedRuntimeInfo().HeartbeatDatastoreInfo.Datastore | Get-VIObjectByVIView

##########################
#	Create a Cluster
##########################
New-Cluster -Name "VMCL-ATSDisabled" -Location "echd-cloud" -DrsAutomationLevel FullyAutomated -HAEnabled -HAAdmissionControlEnabled -HAFailoverLevel 1 -HARestartPriority "High" -HAIsolationResponse "Shutdown"

$clusters = "ArchiveHP","Parsiv1","Parsiv2"

#######################################################
#	DO NOT FORGET TO load function Set-VMCPSettings
#######################################################

ForEach ($cl in $clusters) {
	Write-Host "Creating cluster $cl" -ForegroundColor "Green"
	$clX = New-Cluster -Name $cl -Location (get-datacenter).Name -DrsAutomationLevel FullyAutomated -HAEnabled -HAAdmissionControlEnabled -HAFailoverLevel 1 -HARestartPriority "High" -HAIsolationResponse "Shutdown"
	#$clX = Get-Cluster -Name $cl

	# VM Monitoring
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
	$_this = Get-View -Id $clX.Id
	$_this.ReconfigureComputeResource_Task($spec, $true) | Out-Null
		
	# HA Admission Control
	$percentCPU = "10"
	$percentMem = "10"

	$spec = New-Object VMware.Vim.ClusterConfigSpec
	$spec.DasConfig = New-Object VMware.Vim.ClusterDasConfigInfo
	$spec.DasConfig.AdmissionControlPolicy = New-Object VMware.Vim.ClusterFailoverResourcesAdmissionControlPolicy
	$spec.DasConfig.AdmissionControlPolicy.AutoComputePercentages = $false
	$spec.DasConfig.AdmissionControlPolicy.CpuFailoverResourcesPercent = $percentCPU
	$spec.DasConfig.AdmissionControlPolicy.MemoryFailoverResourcesPercent = $percentMem
	$clX.ExtensionData.ReconfigureCluster($spec,$true) | Out-Null
	
	# Heartbeat Datastore
	$Spec = New-Object VMware.Vim.ClusterConfigSpecEx
	$Spec.DasConfig = New-Object VMware.Vim.ClusterDasConfigInfo
	$Spec.DasConfig.HBDatastoreCandidatePolicy = "allFeasibleDs"
	$clX.ExtensionData.ReconfigureComputeResource_Task($Spec, $true) | Out-Null
	
	# VM Component Protection Settings
	$clX | Set-VMCPSettings -enableVMCP:$True -VmStorageProtectionForPDL restartAggressive -VmStorageProtectionForAPD restartConservative -VmReactionOnAPDCleared none -Confirm:$false | Out-Null
	
}

#######################
#	Rename Cluster
#######################
Get-Cluster VMCL-ATSDisabled | Set-Cluster -Name "VMCL-Test"

######################
#	Remove-Cluster
######################
Get-Cluster -Name "VMCL-ATSDisabled" | remove-Cluster -Confirm:$false

###############################
#	Moving hosts to a cluster
###############################
Move-VMHost @("192.168.16.68","192.168.16.69","192.168.16.70") -location (Get-Cluster Production)
Get-VMHost | Move-VMHost -Location (Get-Cluster "VMCL-ATSDisabled") -Confirm:$false

#####################
#	VM Monitoring	
#####################

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

##############################
#	HA Admission Control
##############################

$percentCPU = "10"
$percentMem = "10"

$clusterName = "VMCL52"
$cluster = Get-Cluster -Name $clusterName

$spec = New-Object VMware.Vim.ClusterConfigSpec
$spec.DasConfig = New-Object VMware.Vim.ClusterDasConfigInfo
$spec.DasConfig.AdmissionControlPolicy = New-Object VMware.Vim.ClusterFailoverResourcesAdmissionControlPolicy
$spec.DasConfig.AdmissionControlPolicy.AutoComputePercentages = $false
$spec.DasConfig.AdmissionControlPolicy.CpuFailoverResourcesPercent = $percentCPU
$spec.DasConfig.AdmissionControlPolicy.MemoryFailoverResourcesPercent = $percentMem
$cluster.ExtensionData.ReconfigureCluster($spec,$true)


#######################
#	Heartbeat Datastore
#######################

$Spec = New-Object VMware.Vim.ClusterConfigSpecEx
$Spec.DasConfig = New-Object VMware.Vim.ClusterDasConfigInfo

$ClusterName = Get-Cluster $Cluster
$Spec.DasConfig.HBDatastoreCandidatePolicy = "allFeasibleDs"
$ClusterName.ExtensionData.ReconfigureComputeResource_Task($Spec, $true)

# http://www.enterprisedaddy.com/2017/06/powercli-set-datastoreheartbeatconfig-change-datastore-hearbeat-configuration/

########################################
#	VM Component Protection Settings
########################################

$cl | Get-VMCPSettings

Set-VMCPSettings -enableVMCP:$True -VmStorageProtectionForPDL restartAggressive -VmStorageProtectionForAPD restartConservative -VmReactionOnAPDCleared none -Confirm:$false

# http://www.dutchvblog.com/powercli/useful-powercli-scripts/
# https://github.com/vmware/PowerCLI-Example-Scripts/blob/master/Modules/VMCPFunctions/VMCPFunctions.psm1

#################
#	DRS Rules	#
#################
#info
Get-DrsRule -Cluster ClusterName | Select Name, Enabled, Type, @{Name="VM"; Expression={ $iTemp = @(); $_.VMIds | % { $iTemp += (Get-VM -Id $_).Name }; [string]::Join(";", $iTemp) }}
Get-DrsClusterGroup -Cluster ClusterName | select Name, Cluster, GroupType, @{Name="Member:"; Expression={[string]::Join(";", $_.Member)}}

#separate vms
New-DrsRule –Cluster 'Lab Cluster' –Name 'antiAffinityTest1' -KeepTogether $false –VM Test1, Test2
New-DrsRule -Cluster CL01 –Name ProxyNLB_separate –KeepTogether:$false –VM Proxy01,Proxy02

#DrsClusterGroup
New-DrsClusterGroup -Name HostsOdd -Cluster Demo -VMHost esx01.corp.local,esx03.corp.local
New-DrsClusterGroup -Name HostsEven -Cluster Demo -VMHost esx02.corp.local,esx03.corp.local

#Example
New-DrsClusterGroup -Name VMsOdd -Cluster $cluster -VM app01,app03,app05
Set-DrsClusterGroup -DrsClusterGroup VMsOdd -VM $VMsOdd –Add
New-DrsClusterGroup -Name VMsEven -Cluster $cluster -VM $VMsEven

Get-DrsClusterGroup
Get-DrsClusterGroup -Type VMgroup
Get-DrsClusterGroup -VM <>
Get-DrsClusterGroup -VMHost <>

New-DrsVMHostRule -Name 'EvenVMsToEvenHosts' -Cluster $cluster -VMGroup VMsEven -VMHostGroup HostsEven -Type ShouldRunOn
New-DrsVMHostRule -Name 'OddVMsToEvenHosts' -Cluster $cluster -VMGroup VMsOdd -VMHostGroup HostsOdd -Type ShouldRunOn
Get-DrsVMHostRule

Get-DrsVMHostRule | Set-DrsVMHostRule -Enabled $false

Remove-DrsVMHostRule -Rule EvenVMsToEvenHosts,OddVMsToOddHosts
Get-DrsClusterGroup | Remove-DrsClusterGroup

#https://blogs.vmware.com/PowerCLI/2017/06/spotlight-new-drs-cmdlets.html