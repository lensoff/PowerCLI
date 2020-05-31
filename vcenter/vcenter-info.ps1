#Name,version,build
$global:DefaultVIServers | Select Name,Version,Build

########################
#	vCenter Unique ID
########################
# I
(Get-AdvancedSetting -Entity $vcserver -Name instance.id).Value
# II
$si = Get-View $global:DefaultVIServers
$setting = Get-View $si.Content.Setting
$setting.QueryOptions("instance.id") | Select -ExpandProperty Value

#############################
#	vCenter SNMP Settings
#############################

#Show the SNMP settings
Get-AdvancedSetting –Entity $srv –Name snmp.*
Get-AdvancedSetting –Entity $srv –Name snmp.receiver.3.* | ft -auto
Get-AdvancedSetting –Entity $srv –Name snmp.receiver.* | ft -auto

#Modify the SNMP receiver data.
$srv = 'mgmtvcenter01.abc.abc'
Get-AdvancedSetting –Entity $srv  –Name snmp.receiver.2.community | Set-AdvancedSetting –Value public
Get-AdvancedSetting –Entity $srv  –Name snmp.receiver.2.enabled | Set-AdvancedSetting –Value $true
Get-AdvancedSetting –Entity $srv  –Name snmp.receiver.2.name | Set-AdvancedSetting –Value 192.168.1.10




#Определение вицентра, под управлением которого были оригинально созданы виртуальные машиины 
Get-VM | sort | ForEach {
	Write-host "VM name is" $_.Name -ForegroundColor "Green"
	$vc = $_.Uid.Split('@')[1].Split(':')[0]
	$macAddress = ($_ | Get-NetworkAdapter).MacAddress
	$macAddressParts = $macAddress.Split(':')
	$Decimal = [System.Convert]::ToInt64($macAddressParts[3], 16)
	$diff = '128'
	$iID = $Decimal - $diff

	$iIDdata = @(
		[PSCustomObject]@{
			vCenter = "vcenter.echd.ru"
			InstanceID = "47"
		},
		[PSCustomObject]@{
			vCenter = "vcenter01.echd.ru"
			InstanceID = "40"
		},
		[PSCustomObject]@{
			vCenter = "mgmtvcenter01.echd.ru"
			InstanceID = "9"
		},
		[PSCustomObject]@{
			vCenter = "elect-vcenter01.echd.ru"
			InstanceID = "55"
		},
		[PSCustomObject]@{
			vCenter = "elect-vcenter02.echd.ru"
			InstanceID = "14"
		},
		[PSCustomObject]@{
			vCenter = "tstvcenter01.echd.ru"
			InstanceID = "60"
		},
		[PSCustomObject]@{
			vCenter = "10.53.42.15"
			InstanceID = "25"
		}    
	)
	$iIDdata | ForEach {
		if ($iID -eq $_.InstanceID) {
			Write-Host "We have a match! VM was created in vCenter" $_.vCenter -ForegroundColor "Yellow"
			Write-Host "And is currently hosting in vCenter" $vc -ForegroundColor "Yellow"
		}
	}
}