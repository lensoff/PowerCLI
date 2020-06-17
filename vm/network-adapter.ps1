###########
#	Info
###########
#vm,nic,portGroup,ip-address
Get-VM | Get-NetworkAdapter | Select-Object @{N="VM";E={$_.Parent.Name}},@{N="NIC";E={$_.Name}},@{N="Network";E={$_.NetworkName}},@{N="IP";E={$_.Parent.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork}}}
#vm,ip
Get-VM | Name,@{N="ip";E={$_.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork}}}
#vm,mac
Get-VM | Select-Object -Property Name,@{"Name"="MAC";"Expression"={($_ | Get-NetworkAdapter).MacAddress}}

#$_.Guest.IPAddress
#$vm.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork}

####################
#	Configuring
####################

$PortGroupName = Get-VDPortGroup ''
get-vm $vm | get-networkadapter | set-networkadapter -PortGroup $PortGroupName –Confirm:$true
get-vm $vm | get-networkadapter | set-networkadapter -Connected:$true -StartConnected:$true –Confirm:$true

##################
#	Untested
##################
Set-VMGuestNetworkInterface -VMGuestNetworkInterface $lan -GuestUser $user -GuestPassword $pass -IP $ip -Netmask $nmask -Gateway $gw
Set-VMGuestNetworkInterface -VMGuestNetworkInterface $vmGuestNetworkInterface -GuestUser User -GuestPassword Pass02 -Netmask 255.255.255.255 -Gateway 10.23.112.58

