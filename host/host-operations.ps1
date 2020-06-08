############
#	Info
############
get-vmhost | select Name,Parent,ConnectionState,Build | sort Build
Get-VMHost |  Where {$_.Name -like "srv09-16*"}

####################
#	Operations
####################
# Place the selected host into Maintenance Mode
$esx | Set-VMHost -State Maintenance -Confirm:$false
# Shutdown the host
$esx | Stop-VMhost -Confirm:$false
# Reboot the host
$esx | Restart-VMhost -Confirm:$false #optional: -Evacuate -Force -RunAsync
# Exit Maintenance Mode
$esx | set-vmhost -State Connected -Confirm:$false

#################################################################
#	Moving hosts between datacenters or clusters with PowerCLI	
#################################################################
#Put the host in maintenance mode
#(Unnecessary) - Move the host out of the cluster
$esx | Move-VMHost -Destination (Get-Datacenter vjlab-dc)
#Move the host to the datacenter
$esx | Move-VMHost -Destination (Get-Datacenter vjlab-vcloud) -Verbose
#Move the host to another cluster
$esx | Move-VMHost -Destination (Get-Cluster vjlab-vcloud)
#Put the ESXi out of maintenance mode
#http://blog.jreypo.io/sysadmin/virtualization/vmware/moving-hosts-between-datacenters-with-powercli/

#############################
#	Reconfigure for HA		#
#############################
Get-Cluster <clusterName> | Get-VMhost | Sort Name | %{$_.ExtensionData.ReconfigureHostForDAS()}
#or
$vmhostView = get-vmhost | select -first 1 | get-view
$vmhostView.ReconfigureHostForDAS_Task() 

#################################
#	Add ESXi Hosts to vCenter	#
#################################
$ESXiHosts = "srv10-01.echd.ru", "srv11-01.echd.ru", "srv12-01.echd.ru", "srv13-01.echd.ru", "srv14-01.echd.ru", "srv15-01.echd.ru", "srv16-01.echd.ru", "srv17-01.echd.ru", "srv18-01.echd.ru"
$esxUsername = "root"
$esxPassword = "12345678"
$DC = Get-Datacenter | Select-Object -First 1
Foreach ($ESXiHost in $ESXiHosts) { 
	Write-Host -ForegroundColor GREEN "Adding ESXi host $ESXiHost to vCenter"
	Add-VMHost -Name $ESXiHost -Location $DC -User $esxUsername -Password $esxPassword -RunAsync -force:$true | Out-Null 
}

#https://www.virtuallyboring.com/add-esxi-hosts-vcenter-using-powershell/
 
Get-Content hosts.txt | Foreach-Object {Add-VMHost $_ -Location (Get-Datacenter Lab) -User root -Password <Password> -RunAsync -force:$true}
#https://www.virten.net/2013/03/add-multiple-esxi-hosts-to-vcenter-with-powercli/

#################
#	Updates
#################
#put the ESXi host VMHost-1 into maintenance mode
Set-VMHost -VMHost VMHost-1 -State Maintenance
#place the critical host baseline into the $Baseline variable for use in future commands
$Baseline = Get-Baseline -Name 'Critical Host Patches (Predefined)'
#ensure the baseline is attached to host
Add-EntityBaseline -Entity VMHost-1 -Baseline $Baseline
#or
Attach-Baseline -Entity VMHost-1 -Baseline $Baseline
#test whether the host is in compliance
Test-Compliance -Entity VMHost-1 -UpdateType HostPatch #-Verbose
Get-Compliance -Entity VMHost-1 -Baseline $Baseline #-ComplianceStatus NotCompliant
#stage the patches to the host
Copy-Patch -Entity VMHost-1 -Confirm:$false
#deploy the patch to my hosts
Update-Entity -Baseline $baseline -Entity VMHost-1 -RunAsync -Confirm:$False

#################
#	Network
#################
#network adapters
$esx | Get-VMHostNetworkAdapter -Physical
#network adapters with zero traffic
$esx | Get-VMHostNetworkAdapter -Physical | Where-Object { $_.BitRatePerSec -eq "0" } | ft VMHost,Name,Mac -autosize
#filtering out unusual network adapters
$esx | Get-VMHostNetworkAdapter -Physical | Where {$_.name -notlike 'vmnic0' -and $_.name -notlike 'vmnic1' -and $_.name -notlike 'vmnic2' -and $_.name -notlike 'vmnic3' -and $_.name -notlike 'vmnic1000202' -and $_.name -notlike 'vmnic1000302'} | select Name,VMHost | ft -autosize
#EsxCli to show network adapters
(Get-EsxCli -VMHost $esx).network.nic.list() | Select Name, Description  

Get-VDPortGroup | Where { $_.VlanConfiguration -like '*602' }
Get-VDPortGroup | Where { $_.VlanConfiguration -like '*602' } | Get-VDswitch | sort NumPorts
Get-Cluster | Get-VMHost | Get-VDSwitch | Get-VDPortGroup

Get-VDPortGroup "MyVDPortgroup" | Get-VDPort -Key "MyPortgroupKey"
Get-VDSwitch "MyVDSwitch" | Get-VDPort -Uplink
Get-VDSwitch "MyVDSwitch" | Get-VDPort -ConnectedOnly

#add a new port group to a virtual switch on each ESX host
foreach ($esx in get-VMhost -Location $cluster_name | sort Name) { $esx | Get-VirtualSwitch -Name $vSwitch | New-VirtualPortGroup -Name “$PortGroupName″ -VlanId $PortGroupVLAN }

#VMHost,Cluster,NIC Driver,NIC Version,NIC Firmware Version
$hosts = get-vmhost
Write-output "Host Name,Cluster,NIC Driver,NIC Version,NIC Firmware Version"
foreach ($esx in $hosts) {
	$cl = get-vmhost $esx | Get-Cluster
    $ECli = Get-esxcli -Vmhost $esx
    $Nics = $Ecli.network.nic.list()    
    foreach ($Nic in $Nics) {
        $NicInfo = $Ecli.network.nic.get($Nic.Name).driverinfo		
        $esx.Name + "," + $cl.Name + "," + $NicInfo.Driver + "," + $NicInfo.Version + "," + $NicInfo.FirmWareVersion
    }
}

########################
#	VMHost,NetworkAdapter,BitRatePerSec,FullDuplex
########################
Get-VMHost srv10-22.echd.ru | Get-VMHostNetworkAdapter |
Where-Object {$_.GetType().Name -eq "PhysicalNicImpl"} |
Select-Object -Property VMHost,Name,BitRatePerSec,FullDuplex,
  @{Name="AutoNegotiate";Expression={
    if ($_.ExtensionData.Spec.LinkSpeed)
      {$false} else {$true}
  }},
  @{Name="LinkState";Expression={
    if ($_.ExtensionData.LinkSpeed)
     {"Up"} else {"Down"}
  }}

#########################
#	Add new PortGroup	#
#########################
$vSwitch = "Production"
$PortGroupName = "VLAN-1102 (Rec-Rostelecom-c)"
$PortGroupVLAN = "1102"
#$PortBinding = "Static" | "Dynamic" | "Ephemeral"
$PortBinding = "Ephemeral"
Get-VDSwitch -Name $vSwitch | New-VDPortGroup -Name $PortGroupName -VlanId $PortGroupVLAN -PortBinding $PortBinding

#############################
#	add hosts to dvswitch	#
#############################
Get-VDSwitch -Name "MyDistributedSwitch" | Add-VDSwitchVMHost -VMHost "VMHost1", "VMHost2"

foreach($ESXi in $List_ESXi)
{
  Write-Host "Add ESXi : $ESXi to VDS : $VDS"
  Get-VDSwitch $vDSSwtich | Add-VDSwitchVMHost -VMHost $ESXi
}

#####################################################
#	add the Virtual Host Adapter to the dvUplinks	#
#####################################################
$UPLINK2 = Get-VMHost $ESXi | Get-VMHostNetworkAdapter -Physical -Name vmnic1
$VDS | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $UPLINK2 -Confirm:$false

###################################
#	Adding new VMKernel adapters
###################################

$csv = "D:\Cisco-IP.csv"
$Data = import-csv $csv -Delimiter ';'
$Data | select Name,Cluster,vMotion,Management
#vmotion
ForEach ($row in $Data) {
	Get-VMHost $row.Name | New-VMHostNetworkAdapter -VirtualSwitch "vMotion" -PortGroup "Mgmt-vMotion-1602" -IP $($row.vMotion) -SubnetMask 255.255.252.0 -VMotionEnabled:$true -Confirm:$false
}
#management
ForEach ($row in $Data) {
	Get-VMHost $row.Name | New-VMHostNetworkAdapter -VirtualSwitch "Management" -PortGroup "mgmtPortGroup-1602" -IP $($row.Management) -SubnetMask 255.255.252.0 -ManagementTrafficEnabled:$true -Confirm:$false
}
###################################
#	Configuring VMKernelGateway
###################################
$net = get-vmhost | Get-VMHostNetwork
$net | Set-VMHostNetwork -VMKernelGateway "$New_VMK_Gateway" -VMKernelGatewayDevice "vmk2" | out-null

##############
#	VSwitch
##############
Get-Cluster | Get-VMHost | Get-VirtualSwitch | Get-VirtualPortGroup
#change the number of ports on my vSwitch
Get-VMHost | % {Get-VirtualSwitch -VMHost $_ -Name $vSwitch | % { Set-VirtualSwitch -VirtualSwitch $_ -NumPorts "$NumberPorts" }}
#create a vSwitch
New-VirtualSwitch -Name $vSwitch -NumPorts $NumPorts -Nic $vmnic

######################################
#	Migrate to different DVSwitches
######################################
$ESXiHosts = "srv10-01.echd.ru", "srv11-01.echd.ru", "srv12-01.echd.ru", "srv13-01.echd.ru", "srv14-01.echd.ru", "srv15-01.echd.ru", "srv16-01.echd.ru", "srv17-01.echd.ru", "srv18-01.echd.ru"
$cl = "ELECL01"

$n = 1
ForEach ($esx in $ESXiHosts) {
	Write-Host "Host name is" $esx -foregroundcolor yellow
	Write-Host $n "from" $Data.Count
	$vmhost = get-vmhost $esx
	
	###############
	
	if ( $cl -eq "ELECL01" ) { 
		$vds1gName = "dvs-election-1g"
		$vds10gName = "dvs-election-10g"
		$vdsiscsi1Name = "dvs-iscsi-election-1"
		$vdsiscsi2Name = "dvs-iscsi-election-2"
	} elseif ( $cl -eq "TestCL01" ) {
		$vds1gName = "dvs-test-1g"
		$vds10gName = "dvs-test-10g"
		$vdsiscsi1Name = "dvs-test-iscsi-1"
		$vdsiscsi2Name = "dvs-test-iscsi-2"
	} else {
		$vds1gName = "dvs-cloud-1g"
		$vds10gName = "dvs-cloud-10g"
		$vdsiscsi1Name = "dvs-iscsi-1"
		$vdsiscsi2Name = "dvs-iscsi-2"
	}
	 
	$vds1g = Get-VDSwitch $vds1gName
	$vds10g = Get-VDSwitch $vds10gName
	$vdsiscsi1 = Get-VDSwitch $vdsiscsi1Name
	$vdsiscsi2 = Get-VDSwitch $vdsiscsi2Name

	$vdswitches = @($vds1gName,$vdsiscsi1Name,$vdsiscsi2Name)
	
	Write-Host "Adding host to dvswitch, uplinks stay unconnected" -ForegroundColor Yellow
	ForEach ($sw in $vdswitches){
		Write-Host "Add Host" $vmhost "to VDSwitch" $sw -ForegroundColor Yellow
		Get-VDSwitch $sw | Add-VDSwitchVMHost -VMHost $vmhost | Out-Null
		Start-Sleep -Seconds 10
	}
	Write-Host "Add Host" $vmhost "to VDSwitch" $vds10g -ForegroundColor Yellow
	$vds10g | Add-VDSwitchVMHost -VMHost $vmhost | Out-Null
	$vds10g | Add-VDSwitchVMHost -VMHost $vmhost | Out-Null

	# Подключаем аплинки на всех свитчах
	Write-Host "Connecting uplinks to dvswitches" -ForegroundColor Yellow

	$DSWdata = @(
		[PSCustomObject]@{
			dvswitch = $vds1gName
			netAdapter = "vmnic0"
		},
		[PSCustomObject]@{
			dvswitch = $vds1gName
			netAdapter = "vmnic1"
		},
		[PSCustomObject]@{
			dvswitch = $vdsiscsi1Name
			netAdapter = "vmnic3"
		},
		[PSCustomObject]@{
			dvswitch = $vdsiscsi2Name
			netAdapter = "vmnic2"
		}
	)

	# $DSWdata = import-csv $csvDSW -Delimiter ';'
	ForEach ($row in $DSWdata){
		$uplink = Get-VMHost $vmhost | Get-VMHostNetworkAdapter -Physical -Name $row.netAdapter
		Get-VDSwitch $row.dvswitch | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $uplink -Confirm:$false | Out-Null
	}

	# Подключаем аплинки к lag
	Write-Host "Connecting uplinks to lags" -ForegroundColor Yellow

	$vds = Get-VDSwitch $vds10gName
	$uplinks = $vmhost | Get-VDSwitch | Get-VDPort -Uplink | where {$_.ProxyHost -like $vmhost.Name}
	#$vmhost | Get-VMHostNetworkAdapter -Name $vmnics | Remove-VirtualSwitchPhysicalNetworkAdapter -Confirm:$false

	$config = New-Object VMware.Vim.HostNetworkConfig
	$config.proxySwitch = New-Object VMware.Vim.HostProxySwitchConfig[] (1)
	$config.proxySwitch[0] = New-Object VMware.Vim.HostProxySwitchConfig
	$config.proxySwitch[0].changeOperation = "edit"
	$config.proxySwitch[0].uuid = $vds.Key
	$config.proxySwitch[0].spec = New-Object VMware.Vim.HostProxySwitchSpec
	$config.proxySwitch[0].spec.backing = New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicBacking
	$config.proxySwitch[0].spec.backing.pnicSpec = New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicSpec[] (4)
	$config.proxySwitch[0].spec.backing.pnicSpec[0] = New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicSpec
	$config.proxySwitch[0].spec.backing.pnicSpec[0].pnicDevice = "vmnic1000202"
	$config.proxySwitch[0].spec.backing.pnicSpec[0].uplinkPortKey = ($uplinks | where {$_.Name -eq "lag1-0"}).key
	$config.proxySwitch[0].spec.backing.pnicSpec[1] = New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicSpec
	$config.proxySwitch[0].spec.backing.pnicSpec[1].pnicDevice = "vmnic1000302"
	$config.proxySwitch[0].spec.backing.pnicSpec[1].uplinkPortKey = ($uplinks | where {$_.Name -eq "lag1-1"}).key

	$_this = Get-View (Get-View $vmhost).ConfigManager.NetworkSystem
	$_this.UpdateNetworkConfig($config, "modify") | Out-Null

	
	################
	
	$n++
	
}

###############################
# Размер IO блоков ISCSI 
##############################
esxcli system settings advanced set -o /ISCSI/MaxIoSizeKB -i 512
get-vmhost hua-01.echd.ru | Get-AdvancedSetting -Name ISCSI.MaxIoSizeKB | Set-AdvancedSetting -Value 512 -Confirm:$false
#rollback
get-vmhost hua-03.echd.ru | Get-AdvancedSetting -Name ISCSI.MaxIoSizeKB | Set-AdvancedSetting -Value 128 -Confirm:$false

#############
#	Syslog	#
#############
$syslog = "[] /scratch/log"
$syslog = "[DATASTORE_NAME] esxi_logs"
Get-Cluster [CLUSTER_NAME] | Get-VMHost | Get-AdvancedSetting -Name Syslog.global.logDir | Set-AdvancedSetting -value $syslog -Confirm:$False
Get-Cluster [CLUSTER_NAME] | Get-VMhost | Get-AdvancedSetting -Name Syslog.global.logDirUnique | Set-AdvancedSetting -Value $True -Confirm:$False
#https://900footvm.wordpress.com/2017/06/09/how-to-set-the-esxi-syslog-directory-with-powercli/

#Report: Cluster,Host,logDir
$table = ForEach ($cl in Get-Cluster | sort ) {
	ForEach ( $vmhost in $cl | Get-VMHost | sort ) {
		$logDir = ($vmhost | Get-AdvancedSetting -Name Syslog.global.logDir).Value
		New-Object PSObject -Property @{
			Host = $vmhost.name
			Cluster = $cl.Name
			logDir = $logDir
		}
	}
}
$table | select Cluster,Host,logDir | Export-Csv -Path "D:\logDirAll.csv" -NoTypeInformation -UseCulture -Encoding UTF8

###############
# Syslog Server
###############
Get-VMHost Esxi001, Esxi002 | Set-VMHostSysLogServer -SysLogServer 'udp://192.168.34.15:514'
Get-VMhostFireWallException -VMhost esxi001.vcloud-lab.com -Name syslog
Get-VMHostFireWallException -VMHost esxi002.vcloud-lab.com -Name Syslog | Set-VMHostFirewallException -Enabled:$True
#or (untested)
Get-VMHost esxi001.vcloud-lab.com | Get-AdvancedSetting -Name Syslog.Global.Loghost | Set-AdvancedSetting -Value udp://10.168.34.15:514 -Confirm:$false
#disabling
Set-VMHostSysLogServer -SysLogServer $null -VMHost Host

#############
#	SNMP
#############
#report: VMHost,Enabled,ReadOnlyCommunities
$hosts | ForEach {
	Write-Host "Starting Loop with host" $_ -ForegroundColor "Yellow"
	Connect-VIServer -Server $_ -User "root" -Password "12345678" | Out-Null
	Get-VMHostSnmp | ft VMHost,Enabled,ReadOnlyCommunities
	Disconnect-VIServer $_ -Confirm:$false
}
#configuring
$sCommunity = ""
$hosts | ForEach {
	Write-Host "Starting Loop with host" $_ -ForegroundColor "Yellow"
	Connect-VIServer -Server $_ -User "root" -Password "12345678" | Out-Null
	Get-VMHostSnmp | Set-VMHostSnmp -Enabled:$true -ReadOnlyCommunity $sCommunity
	Disconnect-VIServer $_ -Confirm:$false
}
#https://9to5it.com/how-to-configure-snmp-on-an-esxi-host/

#################################################
#	CONFIGURE SOFTWARE ISCSI STORAGE ADAPTER 
#################################################
#Добавляем
$VMhost | Get-VMHostStorage | Set-VMHostStorage -SoftwareIScsiEnabled $True
#Смотрим IScsiName
$vmhost | Get-VMHostHba -Type iScsi | Select-Object Name, Status, IScsiName
#Меняем IScsiName
$vmhost | Get-VMHostHba | Where {$_.Type -eq "Iscsi"} | Where {$_.Model -eq "iSCSI Software Adapter"} | Set-VMHostHba -IScsiName "iqn.1998-01.com.vmware:$vmhost"
Get-VMHost | Get-VMHostHba | Where {$_.Type -eq "Iscsi"} | ft VMHost,IScsiName

#$vmhost | Get-VMHostHba -Type iScsi | Where {$_.Model -eq "iSCSI Software Adapter"} | Get-ScsiLun | Get-ScsiLunPath | select name, scsilun, state

#http://vcloud-lab.com/entries/powercli/powercli-vmware-configure-software-iscsi-storage-adapter-and-add-vmfs-datastore
#http://blog.myvmx.com/2018/01/configuring-iscsi-on-esxi-using-powercli.html

#################
#	Enable SSH	#
#################
$VMHost | Get-VMHostService | ? {$_.Key -eq 'TSM-SSH'} | Start-VMHostService -Confirm:$false

#####################
#	FW SSH Client	#
#####################
get-vmhost srv06-01.echd.ru | Get-VMHostFirewallException "SSH Server", "SSH Client"

$FWExceptions = Get-VMHostFirewallException -VMHost $vmhost | where {$_.Name.StartsWith('FTP')}
$FWExceptions | Set-VMHostFirewallException -Enabled $true

$FWExceptions = get-vmhost srv06-01.echd.ru | Get-VMHostFirewallException "SSH Client"
$FWExceptions | Set-VMHostFirewallException -Enabled $true

#esxcli https://ict-freak.nl/2013/05/02/powercli-enable-ssh-and-configure-esxi-firewall/

############
#	NTP
############
#Report: Name,Cluster,vCenter,NTPServer,NTPpolicy,NTPStatus
$table = ForEach ( $esx in Get-Cluster | sort | get-vmhost | sort ) {
	$temp = $esx | Get-VMHostService | Where-Object {$_.key -eq "ntpd"}
	New-Object PSObject -Property @{
		Name = $esx.Name
		Cluster = $esx.Parent
		vCenter = $esx.Uid.Substring($esx.Uid.IndexOf('@')+1).Split(":")[0]
		NTPServer = $esx | Get-VMHostNtpServer
		NTPpolicy = $temp.Policy
		NTPStatus = $temp.Running
	}
}
$table | select Name,Cluster,vCenter,NTPServer,NTPpolicy,NTPStatus | Export-Csv -Path "D:\reportNTP.csv" -NoTypeInformation -UseCulture -Encoding UTF8
Invoke-Item "D:\reportNTP.csv"

#Configure
$hosts = "ficl01-blade19.echd.ru","ficl03-blade52.echd.ru"
ForEach ( $esx in get-vmhost $hosts | sort ) {
	Write-Host $esx.Name -foregroundcolor Yellow
	$esx | Add-VMHostNtpServer ntp.echd.ru | Out-Null
	$esx | Get-VMHostFirewallException | where {$_.Name -eq "NTP client"} | Set-VMHostFirewallException -Enabled:$true | Out-Null
	$esx | Get-VmHostService | Where-Object {$_.key -eq "ntpd"} | Start-VMHostService | Out-Null
	$esx | Get-VmHostService | Where-Object {$_.key -eq "ntpd"} | Set-VMHostService -policy "on" | Out-Null
}

################################
#	Atomic Test and Set (ATS) locking
################################
$clusterName = ''

#Configure
Get-Cluster -Name $clusterName | Get-VMHost |
Get-AdvancedSetting -Name VMFS3.UseATSForHBOnVMFS5 |
Set-AdvancedSetting -Value 0 -Confirm:$false
#Rollback
Get-Cluster -Name $clusterName | Get-VMHost |
Get-AdvancedSetting -Name VMFS3.UseATSForHBOnVMFS5 |
Set-AdvancedSetting -Value 1 -Confirm:$false

#list
$table = ForEach ( $cl in Get-Cluster | sort ) {	
	ForEach ($esx in $cl | get-vmhost | sort) {
		New-Object PSObject -Property @{
			cl = $cl.Name
			esx = $esx.Name
			ats = ($esx | Get-AdvancedSetting -Name VMFS3.UseATSForHBOnVMFS5).Value
		}
	}
}
$table | select cl,esx,ats | Export-Csv -Path "D:\0-Report-Kur-ATS.csv" -NoTypeInformation -UseCulture -Encoding UTF8

#esxcli
esxcli storage vmfs lockmode list

###################################
#	configure fan speed ( supermicro ipmi)
###################################
cd c:\SMCIPMITool_2.23.0_build.191216_bundleJRE_Windows
ForEach ($esx in $hosts) {
	$esxipmi = $esx.Name.Insert(8,'.ipmi')
	Write-Host "Host" $esxipmi -ForegroundColor "Yellow"
	#(& ./SMCIPMITool.exe $esxipmi ADMIN ADMIN ipmi fan)[0]
	Write-Host "Configuring standart speed Fan mode"
	& ./SMCIPMITool.exe $esxipmi ADMIN ADMIN ipmi fan 0 | Out-Null
	(& ./SMCIPMITool.exe $esxipmi ADMIN ADMIN ipmi fan)[0]
	Write-Host " "
}
 
#################################
#	SuppressHyperthreadWarning	#
#################################
get-vmhost | Where {$_.Build -eq "9313334"} | sort | Get-AdvancedSetting UserVars.SuppressHyperthreadWarning | where { $_.Value -eq "0" } | ft Entity,Value

ForEach ( $hosts in  get-vmhost | Where {$_.Build -eq "9313334"} | Get-AdvancedSetting UserVars.SuppressHyperthreadWarning | where { $_.Value -eq "0" } ) {
	Write-Host "Working on host" $hosts -ForegroundColor "Yellow"
	Get-VMHost $hosts.Entity | Get-AdvancedSetting UserVars.SuppressHyperthreadWarning | Set-AdvancedSetting -Value 1 -Confirm:$false
}

#################
#	Reports
#################
# Cluster,Host,HBA,Targets,Devices,Paths
$table = foreach ($cl in Get-Cluster | sort) {
	Write-host ""
	Write-Host $cl.Name
	Write-host ""
	foreach( $esx in $cl | Get-VMHost | sort | where { $_.Name -like "srv*" -And $_.ConnectionState -ne "NotResponding" -And $_.ConnectionState -ne "Disconnected" } ){
		Write-Host $esx.Name
		foreach($hba in (Get-VMHostHba -VMHost $esx -Type "ISCSI")){
			$target = $hba.VMhost.ExtensionData.Config.StorageDevice.ScsiTopology.Adapter | where {$_.Adapter -eq $hba.Key} | ForEach {$_.Target}
			$luns = (Get-ScsiLun -Hba $hba -LunType "disk" -ErrorAction SilentlyContinue).Count
			$nrPaths = $target | ForEach {$_.Lun.Count} | Measure-Object -Sum | select -ExpandProperty Sum
			New-Object PSObject -Property @{
				Host = $esx.Name
				Cluster = $esx.Parent
				HBA = $hba.Name
				Targets = if($target -eq $null){0}else{@($target).Count}
				Devices = $luns
				Paths = $nrPaths
			}
		}
	}	
}
$table | select Host,Cluster,HBA,Targets,Devices,Paths | Export-Csv -Path "D:\paths.csv" -NoTypeInformation -UseCulture -Encoding UTF8
