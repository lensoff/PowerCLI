#############################
#	Collecting information
#############################

# Get-VMHost
Get-VMHost | Get-VMHostStorage
Get-VMHost | Get-ScsiLun -LunType disk
Get-VMHost | Get-Datastore
Get-VMHostHba -VMhost "srv06-20.echd.ru" -Type iScsi | ft -autosize
# Get-ScsiLun
$vmhost | Get-ScsiLun -CanonicalName "naa.*" | ft -autosize
$vmhost | Get-ScsiLun -LunType disk | ft -autosize
Get-ScsiLun -VMhost "srv06-20.echd.ru" -LunType disk | ft -autosize
# get-datastore
Get-Datastore -VMhost "srv06-20.echd.ru" | ft -autosize
get-datastore *ST12-06* | sort | select -First 1 | Get-VMHost | sort | select -First 1 | Get-Cluster
Get-datastore | Where {$_.name -like '*PROD*' -or $_.name -like '*REPL*'} | Get-VM
Get-datastore | Where {$_.name -like '*ST01-01*' } | Get-VM | where { $_.PowerState -eq "PoweredOn"} | ft -autosize
# Measure
(get-datastore | where { $_.Name -match "-g$" } | Measure-Object -Sum CapacityGB).Sum
# Canonical Names
$table = Get-Datastore $dss | Select Name,@{N='CanonicalName';E={$_.ExtensionData.Info.Vmfs.Extent[0].DiskName}},@{N='CapacityGB';E={ [math]::Round($_.CapacityGB) }},@{N='FreeSpaceGB';E={ [math]::Round($_.FreeSpaceGB) }}
$table | select Name,CanonicalName,CapacityGB,FreeSpaceGB | Export-Csv -Path d:\reportTest.csv -NoTypeInformation -UseCulture -Encoding UTF8
# DatastoreFunctions.psm1
Get-VMHostStorage -VMhost "srv06-20.echd.ru" | Format-List *

#############################
#	More complex reports
#############################

# Datastore Info (Naa, Canonical Name, lun id, host lun id)
$csv = Get-Cluster VMCL51 | Get-Datastore | sort |
select Name,CapacityGB,
    @{N='LUN';E={
        $esx = Get-View -Id $_.ExtensionData.Host[0].Key -Property Name
        $dev = $_.ExtensionData.Info.Vmfs.Extent[0].DiskName
        $esxcli = Get-EsxCli -VMHost $esx.Name -V2
        $esxcli.storage.nmp.path.list.Invoke(@{'device'=$dev}).RuntimeName.Split(':')[-1].TrimStart('L')}},
	@{N='CanonicalName';E={$_.ExtensionData.Info.Vmfs.Extent[0].DiskName}}
$csv | Export-Csv -Path "D:\VMCL51-lun-vsphere.csv" -NoTypeInformation -UseCulture -Encoding UTF8

# vmfs6 datastores
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

