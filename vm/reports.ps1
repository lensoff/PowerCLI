######################
#	A Simple Report
######################
$path = "C:\a_simple_report.csv"
$vmtable = foreach($vm in get-vm | sort ){	
	New-Object PSObject -Property @{
		Name = $vm.Name
		NumCpu = $vm.NumCpu
		RAM = $vm.MemoryMB
		HardDiskSizeGB = ($vm | Get-HardDisk | Measure-Object -Sum CapacityGB).Sum
		GuestOS = $vm.ExtensionData.summary.config.guestfullname
	}
}
$vmtable | select Name,NumCpu,RAM,HardDiskSizeGB,GuestOS | Export-Csv -Path $path -NoTypeInformation -UseCulture -Encoding UTF8

###########################
#	An extended report
###########################
$path = "D:\0-an_extended_report.csv"
$vms = get-vm | sort
$cnt = $vms.Count
$count = 1
$vmtable = foreach ($vm in $vms) {
	$StartTime = $(get-date)
	#Write-Host $vm
	$view = $vm | get-view	
	$snap = $vm | Get-snapshot
	$snapCount = ($snap).Count
	$ip1 = $null
	$ip2 = $null
	$ip3 = $null
	$ip4 = $null
	$ip5 = $null
	if ( ($vm.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork}).Count -eq 1 ) { 
		$ip1 = $vm.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork}
	} else { 
		$ip1 = ($vm.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork} | sort)[0] 
	} 
	if ( ($vm.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork}).Count -ge 2 ) { $ip2 = ($vm.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork} | sort)[1] }
	if ( ($vm.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork}).Count -ge 3 ) { $ip3 = ($vm.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork} | sort)[2] }
	if ( ($vm.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork}).Count -ge 4 ) { $ip4 = ($vm.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork} | sort)[3] }
	if ( ($vm.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork}).Count -ge 5 ) { $ip5 = ($vm.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork} | sort)[4] }
	New-Object PSObject -Property @{
		Name = $vm.Name
		PowerState = $vm.PowerState
		IP1 = $ip1
		IP2 = $ip2
		IP3 = $ip3
		IP4 = $ip4
		IP5 = $ip5
		Hostname = $vm.guest.hostname
		NumCpu = $vm.NumCpu
		GuestOS = $vm.ExtensionData.summary.config.guestfullname
		VMHost = $vm.VMHost
		Version = $vm.HardwareVersion
		VMCluster = ($vm | Get-Cluster).Name
		vCenter = $vm.Uid.Split('@')[1].Split(':')[0]
		Datastore = (($vm | Get-Datastore).Name | sort) -join ","
		#Subsystem = $vm.CustomFields.Item("Subsystem")
		#Owner = $vm.CustomFields.Item("Owner")
		#ipAttr = $vm.CustomFields.Item("IP")		
		ToolsVersion = $view.config.tools.toolsversion
		ToolsStatus = $view.Guest.ToolsVersionStatus		
		SnapshotQty = $snapCount
	}
	$count++
	
	clear-host
	Write-Host $count "from" $cnt
	Write-host "Progress:" ([math]::Round($count/$cnt*100, 2)) "%"
}
$vmtable | select Name,PowerState,Hostname,IP1,IP2,IP3,IP4,IP5,GuestOS,Version,VMCluster,vCenter,ToolsVersion,ToolsStatus,SnapshotQty | Export-Csv -Path $path -NoTypeInformation -UseCulture -Encoding UTF8

#####################################
#	An extended report + joined ip addresses + creator + creation date (not futher than 3 days)
#####################################

$start = (get-date).AddDays(-3)
$finish = get-date

$path = "D:\0-an_extended_report_2.csv"
$vms = get-vm | sort
$cnt = $vms.Count
$count = 1
$vmtable = foreach ($vm in $vms) {
	$StartTime = $(get-date)
	#Write-Host $vm
	$view = $vm | get-view
	$event = $vm | Get-VIEvent -Start $start -Finish $finish -Types Info | Where { $_.Gettype().Name -eq "VmBeingDeployedEvent" -or $_.Gettype().Name -eq "VmCreatedEvent" -or $_.Gettype().Name -eq "VmRegisteredEvent" -or $_.Gettype().Name -eq "VmClonedEvent"}
	$snap = $vm | Get-snapshot
	$snapCount = ($snap).Count
	New-Object PSObject -Property @{
		Name = $vm.Name
		PowerState = $vm.PowerState
		#IP = ($vm.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork} | sort | group | Select -ExpandProperty Name) -join ","
		IP = ($vm.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork} | sort) -join ","
		Hostname = $vm.guest.hostname
		NumCpu = $vm.NumCpu
		GuestOS = $vm.ExtensionData.summary.config.guestfullname
		VMHost = $vm.VMHost
		Version = $vm.HardwareVersion
		VMCluster = ($vm | Get-Cluster).Name
		vCenter = $vm.Uid.Split('@')[1].Split(':')[0]
		Datastore = (($vm | Get-Datastore).Name | sort) -join ","
		#Subsystem = $vm.CustomFields.Item("Subsystem")
		#Owner = $vm.CustomFields.Item("Owner")
		#ipAttr = $vm.CustomFields.Item("IP")
		#Creator = $vm.CustomFields.Item("Creator")
		#Environment = $vm.CustomFields.Item("Category")
		#SS = ($vm | Get-TagAssignment -Category SubSystem | sort | Select -ExpandProperty Tag) -join ","
		#TagOwner = ($vm | Get-TagAssignment -Category Owner).Tag.Name
		ToolsVersion = $view.config.tools.toolsversion
		ToolsStatus = $view.Guest.ToolsVersionStatus
		CreatedTime = $event.CreatedTime
		Creator = $event.UserName
		SnapshotQty = $snapCount
	}
	$count++
	$elapsedTime = $(get-date) - $StartTime
	$totalTime = "{0:HH:mm:ss}" -f ([datetime]($elapsedTime.Ticks*($cnt - $count)))

	clear-host
	Write-Host $count "from" $cnt 
	Write-host "Progress:" ([math]::Round($count/$cnt*100, 2)) "%" 
	Write-host "Time for coffee" $totalTime
}
$vmtable | select Name,PowerState,Hostname,IP,GuestOS,Version,VMCluster,vCenter,Creator,CreatedTime,SnapshotQty | Export-Csv -Path $path -NoTypeInformation -UseCulture -Encoding UTF8

