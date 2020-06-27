#############################
#	Collecting information
#############################

# Get-VMHost
Get-VMHost | Get-VMHostStorage
Get-VMHost | Get-ScsiLun -LunType disk
Get-VMHost | Get-Datastore
Get-VMHostHba -VMhost "srv06-20.abc.abc" -Type iScsi | ft -autosize
# Get-ScsiLun
$vmhost | Get-ScsiLun -CanonicalName "naa.*" | ft -autosize
$vmhost | Get-ScsiLun -LunType disk | ft -autosize
Get-ScsiLun -VMhost "srv06-20.abc.abc" -LunType disk | ft -autosize
# get-datastore
Get-Datastore -VMhost "srv06-20.abc.abc" | ft -autosize
get-datastore *ST12-06* | sort | select -First 1 | Get-VMHost | sort | select -First 1 | Get-Cluster
Get-datastore | Where {$_.name -like '*PROD*' -or $_.name -like '*REPL*'} | Get-VM
Get-datastore | Where {$_.name -like '*ST01-01*' } | Get-VM | where { $_.PowerState -eq "PoweredOn"} | ft -autosize
get-datastore | where { $_.Name -like "*ST01-01*" -or $_.Name -like "*ST01-02*"} | sort | ft Name,FileSystemVersion,@{N="vm";E={ ($_ | get-vm).Count }} -auto
$cl | get-datastore | where { $_.Name -like "*ST04-02*" } | ft Name,FileSystemVersion,@{N="vm";E={ ($_ | get-vm).Count }} -auto

# Measure
(get-datastore | where { $_.Name -match "-g$" } | Measure-Object -Sum CapacityGB).Sum
# Canonical Names
$table = Get-Datastore $dss | Select Name,@{N='CanonicalName';E={$_.ExtensionData.Info.Vmfs.Extent[0].DiskName}},@{N='CapacityGB';E={ [math]::Round($_.CapacityGB) }},@{N='FreeSpaceGB';E={ [math]::Round($_.FreeSpaceGB) }}
$table | select Name,CanonicalName,CapacityGB,FreeSpaceGB | Export-Csv -Path d:\reportTest.csv -NoTypeInformation -UseCulture -Encoding UTF8
#Retrieve the Canonical Name(s)
Get-ScsiLun -VMHost "srv06-22.abc.abc" -LunType disk |
Select RuntimeName,CanonicalName,CapacityGB |
Sort-Object -Property {$_.RuntimeName.Split(‘:’)[0],
[int]($_.RuntimeName.Split(‘:’)[1].TrimStart(‘C’))},
{[int]($_.RuntimeName.Split(‘:’)[2].TrimStart(‘T’))},
{[int]($_.RuntimeName.Split(‘:’)[3].TrimStart(‘L’))}
#Retrieve cluster SAN storage systems
$table = ForEach ( $st in $cl | get-datastore | where { $_.Name -notlike "*logs*" -and $_.Name -notlike "*nfs*" } ) {
		$stSplit = ($st.Name.Split('-')[1] + "-" + $st.Name.Split('-')[2] + "-" + $st.Name.Split('-')[4]).ToLower()
		New-Object PSObject -Property @{
			cl = $cl.Name
			st = $stSplit
	}
}
$table | group st | sort Name
#############################
#	More complex reports
#############################

##############################################################
# Datastore Info (Naa, Canonical Name, lun id, host lun id)
##############################################################
$csv = Get-Cluster VMCL51 | Get-Datastore | sort |
select Name,CapacityGB,
    @{N='LUN';E={
        $esx = Get-View -Id $_.ExtensionData.Host[0].Key -Property Name
        $dev = $_.ExtensionData.Info.Vmfs.Extent[0].DiskName
        $esxcli = Get-EsxCli -VMHost $esx.Name -V2
        $esxcli.storage.nmp.path.list.Invoke(@{'device'=$dev}).RuntimeName.Split(':')[-1].TrimStart('L')}},
	@{N='CanonicalName';E={$_.ExtensionData.Info.Vmfs.Extent[0].DiskName}}
$csv | Export-Csv -Path "D:\VMCL51-lun-vsphere.csv" -NoTypeInformation -UseCulture -Encoding UTF8

#####################
# vmfs6 datastores
#####################
$abc = "d:/0-kur-vmfs6.csv"
$table = ForEach ( $cl in get-cluster | sort ) {
	Write-Host $cl.Name
	ForEach ( $ds in $cl | get-datastore | where { $_.FileSystemVersion -like "*6.*" -and $_.Name -notmatch "log" -and $_.Name -notlike "*-s" } | sort ) {
		Write-Host $ds.Name		
		New-Object PSObject -Property @{
			cl = $cl.Name
			name = $ds.Name
			vmfs = $ds.FileSystemVersion
			vm = ($ds | get-vm).Count
			CapacityGB = [math]::Round($ds.CapacityGB)
			FreeSpaceGB = [math]::Round($ds.FreeSpaceGB)
			naa = $ds.ExtensionData.Info.Vmfs.Extent[0].DiskName
		}
	}
}
$table | select cl,name,vmfs,vm,CapacityGB,FreeSpaceGB,naa | Export-Csv -Path $abc -NoTypeInformation -UseCulture -Encoding UTF8

#################################
#	Show Local Intel SSD disk
#################################
$table1 = ForEach ( $cl in get-cluster | sort ) {
	Write-Host $cl.Name

	ForEach ( $vmhost in $cl | get-vmhost | where { $_.ConnectionState -eq "Connected" -or $_.ConnectionState -eq "Maintenance" } | sort ) {
		
		ForEach ( $disk in $vmhost | Get-ScsiLun -luntype Disk | Where { $_.isLocal -eq $True -and $_.CanonicalName -match "intel" } | sort ) {
				
			New-Object PSObject -Property @{
				cl = $cl.Name
				vmhost = $vmhost.Name
				RAM = $vmhost.MemoryTotalGB
				disk = $disk.CanonicalName
				size = $disk.CapacityGB
			}
			
		}
	}
}
$table1 | select cl,vmhost,RAM,disk,size | Export-Csv -Path d:\0\0-kur-depo-test.csv -NoTypeInformation -UseCulture -Encoding UTF8

######################
#	Fibre Channel
######################

#
#	Not mine
#
$CSVName = 'd:\FC.csv'

#Get cluster and all host HBA information and change format from Binary to hex
$list = Get-cluster | sort | Get-VMhost | sort | Get-VMHostHBA -Type FibreChannel | Select @{N="Cluster";E={$_.Name.Parent}},VMHost,Device,@{N="WWN";E={"{0:X}" -f $_.PortWorldWideName}}

#Go through each row and put : between every 2 digits
foreach ($item in $list){
   $item.wwn = (&{for ($i=0;$i -lt $item.wwn.length;$i+=2)   
                    {     
                        $item.wwn.substring($i,2)   
                    }}) -join':' 
}

#Output CSV to current directory.
$list | export-csv $CSVName -NoTypeInformation -UseCulture -Encoding UTF8

#
#	Collecting hosts' WWN info
#
$vmtable = foreach($cl in get-cluster | sort){
	#$cl
	foreach($vmhost in $cl | get-vmhost | sort){
		#$vmhost
		foreach($hba in $vmhost | Get-VMHostHBA -Type FibreChannel | sort){
			#$hba
			New-Object PSObject -Property @{
				Cluster = $cl.Name
				VMHost = $vmhost.Name
				Device = $hba.Device				
				NodeWWN = "{0:X}" -f $hba.NodeWorldWideName
				PortWWN = "{0:X}" -f $hba.PortWorldWideName
			}	
		}
	}	
}
foreach ($item in $vmtable){
   $item.NodeWWN = (&{for ($i=0;$i -lt $item.NodeWWN.length;$i+=2)   
                    {     
                        $item.NodeWWN.substring($i,2)   
                    }}) -join':' 
}
foreach ($item in $vmtable){
   $item.PortWWN = (&{for ($i=0;$i -lt $item.PortWWN.length;$i+=2)   
                    {     
                        $item.PortWWN.substring($i,2)   
                    }}) -join':' 
}
$vmtable | select Cluster,VMHost,Device,NodeWWN,PortWWN | Export-Csv -Path "D:\test.csv" -NoTypeInformation -UseCulture -Encoding UTF8

########################
#	Multipath policy	
########################
$output=@()
ForEach($VMHost in get-cluster VMCL08 | get-vmhost | sort){
	Write-Warning "Grabbing Data for $VMHost"
	ForEach($lun in ($VMHost | Get-ScsiLun -luntype Disk | Where { $_.MultipathPolicy -ne "Fixed" } | sort MultipathPolicy)){
		$collect="" | select "Host","Cluster","Datastore","Canonicalname", "MultipathPolicy"
		$collect.Host=$VMHost.name
		$collect.Cluster=$VMHost.Parent
		$collect.canonicalname=$lun.CanonicalName
		$collect.multipathpolicy=$lun.MultipathPolicy
		$collect.Datastore = (Get-Datastore | ? {($_.extensiondata.info.vmfs.extent | select -expand diskname) -like $lun.CanonicalName}).Name
		$output+=$collect
	}
}
$output | ft -auto
$output | Out-File C:\datastoresprod.csv

Get-VMHost | Get-ScsiLun -LunType disk | Set-ScsiLun -MultipathPolicy "RoundRobin"

###########################################
#	Суммарный объем датасторов на СХД
###########################################
$csv = "D:\VNX-IP.csv"
$Data = import-csv $csv -Delimiter ';'
$abc = "d:/0-niz-st.csv"
$table = ForEach ($row in $Data) {
	Write-Host $row.Name
	$x = get-datastore *$($row.Name)*
	$y = [math]::Round(($x | Measure-Object -Sum CapacityGB).Sum / 1024)
	$z = [math]::Round(($x | Measure-Object -Sum FreeSpaceGB).Sum / 1024)	
	New-Object PSObject -Property @{
		Name = $row.Name		
		CapacityTB = $y
		FreeSpaceTB = $z		
	}
}
$table | select Name,CapacityTB,FreeSpaceTB | Export-Csv -Path $abc -NoTypeInformation -UseCulture -Encoding UTF8

###########
#	silver datastores, vms on them, migrate vms to bronze
###########
# серебряные датасторы по кластерам
$abc = "d:/0-kur-VMCL-s.csv"
$table = ForEach ( $cl in get-cluster VMCL* | sort ) {# | where { $_.Name -ne "VMCL07" -and $_.Name -ne "VMCL08" -and $_.Name -ne "VMCL18" } | sort ) {
	Write-Host $cl.Name
	ForEach ( $ds in $cl | get-datastore | where { $_.Name -match ".*-s$" } | sort ) {
		Write-Host $ds.Name		
		New-Object PSObject -Property @{
			cl = $cl.Name
			name = $ds.Name
			vm = ($ds | get-vm).Count
			CapacityGB = [math]::Round($ds.CapacityGB)
			FreeSpaceGB = [math]::Round($ds.FreeSpaceGB)
			naa = $ds.ExtensionData.Info.Vmfs.Extent[0].DiskName
		}
	}
}
$table | select cl,name,vm,CapacityGB,FreeSpaceGB,naa | Export-Csv -Path $abc -NoTypeInformation -UseCulture -Encoding UTF8
$table = $table | where { $_.vm -ne 0 }
$CLs = ($table | group cl).Name
# виртуальные машины по кластерам, по серебряным датасторам
$tableVM = ForEach ( $row in $table ) {
	Write-Host $row.name
	ForEach ( $vm in get-datastore $row.name | get-vm | sort ) {
		New-Object PSObject -Property @{
			cl = $row.cl
			ds = $row.name
			vm = $vm.Name
			shddName = ($vm | get-harddisk | where { $_.Filename -match '\-s\]' }).Name
			shddSizeGB = ($vm | get-harddisk | where { $_.Filename -match '\-s\]' }).CapacityGB
			bhddName = ($vm | get-harddisk | where { $_.Filename -match '\-b\]' }).Name
			bhddDS = ($vm | get-harddisk | where { $_.Filename -match '\-b\]' }).Filename.Split('\[')[1].Split('\]')[0]
			bhddSizeGB = ($vm | get-harddisk | where { $_.Filename -match '\-b\]' }).CapacityGB
		}
	}
}
$tableVM | ft cl,ds,vm,shddName,shddSizeGB,bhddName,bhddDS
$tableVM | select cl,ds,vm,shddName,shddSizeGB | Export-Csv -Path d:\0-kur-vm-s.csv -NoTypeInformation -UseCulture -Encoding UTF8
# миграция sda виртуальных машин с серебра на бронзу
ForEach ( $cl in $CLs ) {
	
	Write-Host $cl  -ForegroundColor "Yellow"
	Write-Host " "
	$Data = $tableVM | Where {$_.cl -eq $cl}
	$Data | ft
	
	Read-Host -Prompt "Press Enter to continue or close the PS window to quit" 
	
	ForEach ( $row in $Data ) {
		Write-Host $row.vm ":" $row.ds "->" $row.bhddDS
		#Write-Host $row.ds "->" $row.bhddDS
		Write-Host " "
		#Write-Host "Get-VM" $row.vm "| Get-HardDisk | where {$_.Filename -match" $row.ds "} | Move-HardDisk -Datastore" $row.bhddDS "-Confirm:$false | Out-Null"
		#Get-VM $row.vm | Get-HardDisk | where {$_.Filename -match $row.ds } | Move-HardDisk -Datastore $row.bhddDS -Confirm:$false | Out-Null
		Get-VM $row.vm | Move-VM -Datastore $row.bhddDS | Out-Null
	}

}