##########
#	Info
##########

#vm,Cluster,VMHost,Datastore
Get-VM | Select Name,@{N="Cluster";E={Get-Cluster -VM $_}},VMHost,@{N="Datastore";E={Get-Datastore -VM $_}}
#vm,vmhost,vcenter
Get-VM | ft Name,VMHost,@{N='Server';E={$_.Uid.Split('@')[1].Split(':')[0]}}
#vm,"data"-datastore
get-cluster "VMCL51" | Get-vm | select Name,@{N="hddDS";E={(get-vm $_ | get-datastore | where { $_.Name -like "*Data*" }).Name}}
#vm,ip,"data"-datastore
$cl | get-vm | sort | select Name,@{N="ip";E={$_.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork}}},@{N="hddDS";E={(get-vm $_ | get-datastore | where { $_.Name -like "*Data*" }).Name.Split("_")[1]}} | Export-Csv -Path d:\0\0-niz-vmcl61-62.csv -NoTypeInformation -UseCulture -Encoding UTF8
#vm,cluster
Get-VM | Select-Object -Property Name,@{Name=’Cluster’;Expression={$_.VMHost.Parent}}
#vm,datastore,folder
Get-VM | Select Name,@{N="Datastore";E={[string]::Join(',',(Get-Datastore -Id $_.DatastoreIdList | Select -ExpandProperty Name))}},@{N="Folder";E={$_.Folder.Name}}
#vm,powerstate,version,description
Get-vm | where { $_.PowerState -eq "PoweredOn" } | select powerstate, version, description
#vm,UsedSpaceGB,ProvisionedSpaceGB
get-vm | Select Name, UsedSpaceGB, ProvisionedSpaceGB
#vm,hostname with hostname filter
((get-cluster VMCL* | get-vm *REC* | where { $_.guest.hostname -notlike "*n-*" -and $_.Name -notmatch "test" }  | sort) | select Name,@{N="hostname";E={$_.guest.hostname}}).Count

#################
#	Get-View	#
#################
$view = get-view –viewtype VirtualMachine –filter @{"Name"="zbx-node1"}

##################
#	Filters
##################
#filter by ip
#I
Get-VM | Where-Object {$_.Guest.IPAddress -eq "10.200.154.10"} | select Name,VMHost,Folder
#II
$list = Get-View -ViewType VirtualMachine | Select name,@{N='IP';E={[string]::Join(',',$_.Guest.ipaddress)}}
$list | ?{ $_.ip -eq "10.200.201.165" }

#filter by hostname
get-vm *REC* | where { $_.guest.hostname -notlike "*n-*" -and $_.Name -notmatch "test" }
#filter by name
Get-VM |  Where {$_.Name -like "parsive*" -and $_.Name -notlike "*axxon*" -and $_.Name -notlike "*vpn*"} | sort
# Выбор машин из ip диапазона
#I
$startOctet = 1
$endOctet = 7
get-vm *REC-F0-Test | where { ([byte[]] $_.Guest.IPAddress[0].Split(".")[3]) -le $endOctet -and ([byte[]] $_.Guest.IPAddress[0].Split(".")[3]) -ge $startOctet } | sort | ft -auto Name,@{N="IP Address";E={@($_.guest.IPAddress[0])}}
#II
$ipdb = "10.200.200.75","10.200.200.76","10.200.200.77","10.200.200.78","10.200.200.80","10.200.200.83","10.200.200.85"
$list = Get-View -ViewType VirtualMachine | Select name,@{N='IP';E={[string]::Join(',',$_.Guest.ipaddress)}}
ForEach ($ip in $ipdb) {
	$vm = ($list | ?{ $_.ip -eq $ip }).Name
	Write-Host $vm -foregroundcolor yellow
	get-vm $vm | get-harddisk | select -skip 1 | select -first 1 | ft -auto Filename,CapacityGB	
}

##################
#	Reports
##################

#A Simple Report
$path = "D:\0-elect02-vm-report.csv"
$vmtable = foreach($vm in get-vm | sort ){
	New-Object PSObject -Property @{
		Name = $vm.Name
		Hostname = $vm.guest.hostname
		PowerState = $vm.PowerState
		#NumCpu = $vm.NumCpu
		#RAM = $vm.MemoryMB
		#HardDiskSizeGB = ($vm | Get-HardDisk | Measure-Object -Sum CapacityGB).Sum
		GuestOS = $vm.ExtensionData.summary.config.guestfullname
		IP = ($vm.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork} | sort) -join ","
	}
}
$vmtable | select Name,PowerState,Hostname,GuestOS,IP | Export-Csv -Path $path -NoTypeInformation -UseCulture -Encoding UTF8

#Рекордеры старого типа по кластерам
$table = ForEach ( $cl in get-cluster VMCL* | sort ) {
	Write-Host $cl.Name
	ForEach ( $vm in $cl | get-vm *REC* | where { $_.guest.hostname -notlike "*n-*" } | sort ) {
		Write-Host $vm.Name		
		New-Object PSObject -Property @{
			cl = $cl.Name			
			vm = $vm.Name
			hostname = $vm.guest.hostname
		}
	}
}
$table | select cl,vm,hostname | Export-Csv -Path d:\0\0-kur-rec-old.csv -NoTypeInformation -UseCulture -Encoding UTF8
#Рекордеры, расположенные на серебре
$abc = "d:\0\0-kur-rec-silver.csv"
$table = ForEach ( $cl in get-cluster VMCL* | sort ) {
	Write-Host $cl.Name
	ForEach ( $ds in $cl | get-datastore | where { $_.Name -match "-s$" } | sort ) {
		Write-Host $ds.Name
		ForEach ( $vm in $ds | get-vm *REC* | sort ) {
			New-Object PSObject -Property @{
				cl = $cl.Name
				ds = $ds.Name
				vm = $vm.Name
				hostname = $vm.guest.hostname
			}
		}
	}
}
$table | select cl,ds,vm,hostname | Export-Csv -Path $abc -NoTypeInformation -UseCulture -Encoding UTF8
invoke-item $abc

#Количество свободного места под рекордеры в кластерах
$abc = "d:/0-kur-vmcl-vm.csv"
$table = ForEach ( $cl in get-cluster *VMCL* | where { $_.Name -ne "VMCL18" } | sort ) {
	Write-Host $cl.Name
	$vms = ($cl | get-vm).Count
	New-Object PSObject -Property @{
		cl = $cl.Name
		vm = $vms
		vmCapacity = 60 - $vms
	}

}
$table | select cl,vm,vmCapacity | Export-Csv -Path $abc -NoTypeInformation -UseCulture -Encoding UTF8
invoke-item $abc