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

##################
#	Filters
##################
#filter by ip
Get-VM | Where-Object {$_.Guest.IPAddress -eq "10.200.154.10"} | select Name,VMHost,Folder
#filter by hostname
get-vm *REC* | where { $_.guest.hostname -notlike "*n-*" -and $_.Name -notmatch "test" }
#filter by name
Get-VM |  Where {$_.Name -like "parsive*" -and $_.Name -notlike "*axxon*" -and $_.Name -notlike "*vpn*"} | sort

##################
#	Reports
##################

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
$table | select cl,ds,vm,hostname | Export-Csv -Path d:\0\0-kur-rec-silver.csv -NoTypeInformation -UseCulture -Encoding UTF8


