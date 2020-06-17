$FWExceptions = get-vmhost srv18-11.echd.ru | Get-VMHostFirewallException "SSH Client"
$FWExceptions | Set-VMHostFirewallException -Enabled $true

#######################################

# source
cd -P /vmfs/volumes/InfraCL01-ST05-02-L101-s
# destination
cd -P /vmfs/volumes/InfraCL_FICL02-VNX014_OS_6
#5b869c4c-9fae7266-cd4d-0025b501a89d
watch -n 5 ls -lh
# source
scp -r zbx-proxy-niz-node1 root@ficl03-blade073.echd.ru:/vmfs/volumes/5b869c4c-9fae7266-cd4d-0025b501a89d

#######################################

$FWExceptions | Set-VMHostFirewallException -Enabled $false

