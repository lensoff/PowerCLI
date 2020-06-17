#############################
#	rescan hba and vmfs		
#############################
$hosts | Get-VMHostStorage -RescanAllHba -RescanVmfs

$i = 1
$count = (get-folder Spare,ZIP | get-vmhost).Count
ForEach ( $fld in get-folder "Spare","ZIP" ) {
	Write-Host $fld.Name -ForegroundColor "Yellow"
	ForEach ( $esx in get-folder $fld | get-vmhost | sort ) {		
		Write-Host $i "from" $Count
		Write-Host $esx.Name
		Write-Host ""
		$esx | Get-VMHostStorage -RescanAllHba -RescanVmfs | Out-Null
		$i++
	}
}
	
################################
#	rescan with workflow
################################
$cl = ''
$hosts = (get-cluster $cl | get-vmhost | sort).Name
$vPass = ''
Workflow Rescan-WF {

	Param (
		[Parameter(Mandatory=$true, Position=0)]
		[string[]] $hosts,	
		[Parameter(Mandatory=$true, Position=1)]
		[string] $vCenter,
		[Parameter(Mandatory=$true, Position=2)]
		[string] $User,
		[Parameter(Mandatory=$true, Position=3)]
		[string] $Password
	)	
		
	# Цикл, который будет выполняться параллельно
	foreach -parallel ( $vmhost in $hosts ) {
		# Это скрипт, который видит только свои переменные и те, которые ему переданы через $Using
		InlineScript {
			$a = Connect-VIServer -Server $Using:vCenter -User $Using:User -Password $Using:Password
			
			Write-Host "Rescanning" $Using:vmhost
			Write-Host ""
			get-vmhost $Using:vmhost | Get-VMHostStorage -RescanAllHba -RescanVmfs | Out-Null
			
			$a | Disconnect-VIServer -Confirm:$false
		}
	}
}
Rescan-WF $hosts $global:DefaultVIServer.Name $global:DefaultVIServer.User $vPass

#########################
#	Create Datastores	
#########################
# I. csv:
Datastore_Name,Naa_Id
VMFS_Datastore_PowerCli_3,naa.6742b0f00000758f0000000000000082

$data = Import-Csv C:\details.csv
foreach ($line in $data) {
	New-Datastore -VMHost "172.17.72.18" -Name $($line.Datastore_Name) -Path $($line.Naa_Id) -vmfs -FileSystemVersion 5
}

# II.
$hosts | New-Datastore -Name 'VMCL03-ST01-01-L107-s' -Path 'naa.60080e5000474fc000000b525a54764c' -Vmfs -Confirm:$False

#########################
#	Remove Datastores	
#########################
$dss = ""
ForEach ($ds in get-datastore $dss | sort) {
	$vmhost = $ds | get-vmhost | where { $_.ConnectionState -eq "Connected" -or $_.ConnectionState -eq "Maintenance" } | Get-Random -Count 1
	Write-Host "Deleting $ds from host $vmhost"
	Remove-Datastore -Datastore $ds -VMHost $vmhost -Confirm:$false	
}
#########################
#	Remove datastore1*	
#########################

$targetHosts = get-datastore "datastore1*"  | get-vmhost | sort
Foreach ($esx in $targetHosts) {
	Write-Host "Host $($esx.name)" -ForegroundColor GREEN
	$esx | Get-Datastore -Name "datastore1*" | Remove-Datastore -VMHost $esx -WhatIf #-Confirm:$false
}
Get-VMHost "srv18-22.echd.ru" | Get-Datastore -Name "datastore1*" | Remove-Datastore -VMHost (Get-VMHost "srv18-22.echd.ru") -WhatIf

#########################
#	Rename Datastores	
#########################
Get-Datastore -Name Datastore1 | Set-Datastore -Name Datastore2
#changing cluster part in datastore name
ForEach ( $ds in $cl | get-datastore | where { $_.Name -notlike "$($cl.Name)*" } | sort ) {
	#$Name = $ds.Name.Replace($ds.Name.Split('-')[0],$cl.Name).Replace('15-6','15-06')
	$Name = $ds.Name.Replace($ds.Name.Split('-')[0],$cl.Name)
	Write-Host "Renaming $ds to $Name" -ForegroundColor "Yellow"
	#$ds | Set-Datastore -Name $Name
}

#########################
#	Expand a datastore	
#########################

#GUI: datastore - configure - device backing - select device - capacity

#one datastore
$datastore = get-datastore "VMCL08-ST08-06-L101-b"
$esxi = Get-View -Id ($Datastore.ExtensionData.Host |Select-Object -last 1 | Select -ExpandProperty Key) 
$datastoreSystem = Get-View -Id $esxi.ConfigManager.DatastoreSystem
$expandOptions = $datastoreSystem.QueryVmfsDatastoreExpandOptions($datastore.ExtensionData.MoRef)
$datastoreSystem.ExpandVmfsDatastore($datastore.ExtensionData.MoRef,$expandOptions.spec)

#several datastores
ForEach ( $datastore in $cl | get-datastore | where { $_.Name -like "*ST17-06*" } | sort ) {	
	Write-Host "Expanding datastore $datastore" -ForegroundColor "Yellow"
	$esxi = Get-View -Id ($Datastore.ExtensionData.Host | Select-Object -last 1 | Select -ExpandProperty Key)
	$datastoreSystem = Get-View -Id $esxi.ConfigManager.DatastoreSystem
	$expandOptions = $datastoreSystem.QueryVmfsDatastoreExpandOptions($datastore.ExtensionData.MoRef)
	$datastoreSystem.ExpandVmfsDatastore($datastore.ExtensionData.MoRef,$expandOptions.spec) | Out-Null
}
#Checking
$cl | get-datastore | where { $_.Name -like "*ST17-06*" } | sort

#############################
#	Disable auto-rescan
#############################
$srv = 'vcenter01'
Get-AdvancedSetting –Entity $srv –Name config.vpxd.filter.hostRescanFilter | Set-AdvancedSetting –Value false
#or
Get-AdvancedSetting –Entity $global:defaultVIServers –Name config.vpxd.filter.hostRescanFilter | Set-AdvancedSetting –Value false

#################################
#	DatastoreFunctions.psm1		#
#################################
#Import-Module D:\DatastoreFunctions.ps1
Get-Datastore | Get-DatastoreMountInfo | Sort Datastore, VMHost | ft -autosize
Get-VMHostStorage -VMhost "srv06-20.echd.ru" | Format-List *
Get-Datastore SAN01_VMFS0* | Unmount-Datastore
Get-Datastore SAN01_VMFS0* | Detach-Datastore



##########################################################
#	Deleting vmfs 6 ds and creating vmfs 5	(Semi-Auto)
##########################################################

$csv = "D:\0-kur-VMCL12-vmfs6.csv"
$Data = import-csv $csv -Delimiter ';'
$Data | select cl,name,CapacityGB,FreeSpaceGB

$CLs = ($Data | group cl).Name
ForEach ( $cl in $CLs ) {
	$dss = import-csv $csv -Delimiter ';' | Where {$_.cl -eq $cl}
	$esx = Get-Cluster $cl | get-vmhost | where { $_.ConnectionState -eq "Connected" -or $_.ConnectionState -eq "Maintenance" } | select -first 1
	Write-Host $esx.Parent "|" $esx.Name
	Write-Host " "
	ForEach ( $ds in $dss ) {
		Write-Host "Deleting datastore" $ds.name
		Remove-Datastore $ds.name -VMHost $esx -Confirm:$false | Out-Null
		Start-Sleep 10
		Write-Host "Creating datastore" $ds.name "with canonical name" $ds.naa
		New-Datastore -VMHost $esx -Name $ds.name -Path $ds.naa -vmfs -FileSystemVersion 5 | Out-Null
	}
	Write-Host " "
}
#################################################
# Deleting vmfs 6 ds and creating vmfs 5 (Auto)
#################################################
$CLs = "VMCL09"
ForEach ( $cl in $CLs ) {
	$filter = "ST" + $cl.Split("L")[1]
	$dss = get-cluster $cl | get-datastore | where { $_.FileSystemVersion -like "*6.*" -and $_.Name -notlike "*log*" -and $_.Name -like "*$($filter)*" } | sort
	#$dss | select Name,FileSystemVersion

	$esx = Get-Cluster $cl | get-vmhost | where { $_.ConnectionState -eq "Connected" -or $_.ConnectionState -eq "Maintenance" } | select -first 1
	Write-Host $esx.Parent "|" $esx.Name
	Write-Host " "
	ForEach ( $ds in $dss ) {
		if ( ( get-datastore $ds | get-vm ).Count -eq 0) {
			$dsName = $ds.Name
			$dsNAA = $ds.ExtensionData.Info.Vmfs.Extent[0].DiskName
			Write-Host "Deleting datastore" $dsName
			Remove-Datastore $dsName -VMHost $esx -Confirm:$false | Out-Null
			Wait 10
			Write-Host "Creating datastore" $dsName "with canonical name" $dsNAA
			New-Datastore -VMHost $esx -Name $dsName -Path $dsNAA -vmfs -FileSystemVersion 5 | Out-Null
		} Else { Write-Host $ds "has one or move vms" -ForegroundColor "Yellow" }
	}
	Write-Host " "
}
#Checking
get-cluster $cl | get-datastore | where { $_.FileSystemVersion -like "*6.*" } | sort

######################################################################
#	FIND FREE OR UNASSIGNED STORAGE LUN DISKS AND CREATE DATASTORE	
######################################################################
#find all UNASSIGNED luns
$vmhost = $hosts | select -first 1
$vmhost | Get-VMHostStorage -RescanAllHba -RescanVmfs
$AllLUNs = $vmhost | Get-ScsiLun -LunType disk
$Datastores = $vmhost | Get-Datastore
$dsTable = foreach ($lun in $AllLUNs) {
	$Datastore = $Datastores | Where-Object {$_.extensiondata.info.vmfs.extent.Diskname -Match $lun.CanonicalName}
	if ($Datastore.Name -eq $null) {
		$lun | Where CanonicalName -like "naa.*" | Select-Object CanonicalName, CapacityGB, Vendor, @{N='LUN';E={$_.RuntimeName.Split(':')[-1].TrimStart('L')}}
	} 
}
$dsTableSort = $dsTable | sort LUN
$dsTableSort | ft -autosize
Read-Host -Prompt "Press Enter continue or CTRL+C to quit"
#creating datastores
#ForEach ($row in $dsTableSort | where { $_.CanonicalName -ne 'naa.60080e5000475074000035095b9b2a92' -And $_.CanonicalName -ne 'naa.60080e50004750740000350a5b9b2ad4' } ){}
ForEach ($row in $dsTableSort ){
	$lunID = $row.LUN
	$stID = $row.LUN.Substring(1,1)
	#$ds = "VMCL09-ST09-0$stID-L$lunID-b"
	$ds = "ELECL01-ST05-02-L$lunID-s"
	Write-Host "Creating datastore $ds with CanonicalName" $row.CanonicalName "on" $vmhost -ForegroundColor "Yellow"
	$vmhost | New-Datastore -Name $ds -Path $row.CanonicalName -Vmfs -FileSystemVersion 5 | Out-Null
}
#rescan
$hosts | where { $_ -ne $vmhost } | Get-VMHostStorage -RescanAllHba -RescanVmfs
#checking that all hosts have equal datastore quantity
$table = ForEach ($esx in $hosts){
	#Write-host "host" $esx.Name
	$ds = ($esx | get-datastore | measure | Select-Object Count).Count
	#Write-host "ds qty" $ds
	New-Object PSObject -Property @{
		host = $esx.Name
		dsQty = $ds
	}
}
$table | group dsQty

################################################################################
#	Unmount and Detach Datastore (it's faster to delete and create new ones)
################################################################################
$i = 1
foreach ($esx in $hosts){
	Write-Host ""
	Write-Host "Starting loop with host" $esx.Name -ForegroundColor "Green"
	Write-Host $i "from" $hosts.Count -ForegroundColor "Green"
	Write-Host ""
	foreach ($ds in Get-Datastore -Name $datastores){
		Write-Host "Starting loop with ds" $ds.Name -ForegroundColor "Yellow"
		$naa = $ds.ExtensionData.Info.Vmfs.Extent[0].DiskName
		$storSys = Get-View $esx.ExtensionData.ConfigManager.storageSystem
		$device = $storsys.StorageDeviceInfo.ScsiLun | where {$_.CanonicalName -eq $naa}
		# Unmount disk
		Write-Host "Unmounting ds with name" $naa "from host" $esx.Name
		if($device.OperationalState[0] -eq 'ok'){
			#Write-Host "Unmounting VMFS Datastore $($ds.Name) from host $($esx.Name)"
			$storSys.UnmountVmfsVolume($ds.ExtensionData.Info.Vmfs.Uuid)
		}
		# Detach disk
		Write-Host "Detaching ds" $device.Uuid "from host" $esx.Name
		$storSys.DetachScsiLun($device.Uuid)
	}
	$i++
}
$hosts | Get-VMHostStorage -RescanAllHba -RescanVmfs

#########################
#	Storage IO Control	
#########################
Set-Datastore $datastore1, $datastore2 -StorageIOControlEnabled $true
Get-Datastore $ds | Get-View | Select Name, @{N="SIOC Enabled?";E={$_.IORMConfiguration.Enabled}}
Get-View -ViewType datastore | Select Name, @{N="SIOC Enabled?";E={$_.IORMConfiguration.Enabled}}


#########################
#	Configuring iSCSI	
#########################
$vmhost | Get-VMHostStorage | Set-VMHostStorage -SoftwareIScsiEnabled $True
$vmhost | Get-VMHostHba | Where {$_.Type -eq "Iscsi"} | Where {$_.Model -eq "iSCSI Software Adapter"} | Set-VMHostHba -IScsiName "iqn.1998-01.com.vmware:$vmhost"

$ESXiHosts = "srv13-01.echd.ru", "srv14-01.echd.ru", "srv15-01.echd.ru", "srv16-01.echd.ru", "srv17-01.echd.ru", "srv18-01.echd.ru"
ForEach ( $vmhost in $ESXiHosts ) {
	get-vmhost $vmhost | Get-VMHostStorage | Set-VMHostStorage -SoftwareIScsiEnabled $True
	get-vmhost $vmhost | Get-VMHostHba | Where {$_.Type -eq "Iscsi"} | Where {$_.Model -eq "iSCSI Software Adapter"} | Set-VMHostHba -IScsiName "iqn.1998-01.com.vmware:$vmhost"
}
