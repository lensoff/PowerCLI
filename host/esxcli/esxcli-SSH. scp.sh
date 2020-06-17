$FWExceptions = get-vmhost srv07-07.abc.abc | Get-VMHostFirewallException "SSH Client"
$FWExceptions | Set-VMHostFirewallException -Enabled $true

##########################

cd /vmfs/volumes/5be1c101-e199e44c-722a-ac1f6b26cde8/CentOS7-MGT/
scp CentOS7-MGT-flat.vmdk root@srv18-11.abc.abc:/vmfs/volumes/5a733171-5f4936e4-03f3-ac1f6b26ca46/CentOS7-MGT

https://kb.vmware.com/s/article/1918

cd -P /vmfs/volumes/InfraCL01-ST05-02-L101-s/zbx-proxy-niz-node1
cd zbx-proxy-niz-node1/
scp $(ls) root@srv18-11.abc.abc:/vmfs/volumes/5a733171-5f4936e4-03f3-ac1f6b26ca46/CentOS7-MGT

###########

# source
cd -P /vmfs/volumes/InfraCL01-ST05-02-L101-s
# destination
cd -P /vmfs/volumes/InfraCL_FICL02-VNX014_OS_6
#5b869c4c-9fae7266-cd4d-0025b501a89d
watch -n 5 ls -lh
# source
scp -r CentOS7-MGT root@srv08-02.abc.abc:/vmfs/volumes/5be1c5bb-95e2439c-6e81-ac1f6b26c980

############################

$FWExceptions | Set-VMHostFirewallException -Enabled $false

############################

\cp -R ./* /vmfs/volumes/5be1a0b0-cb3b93fa-7239-ac1f6b26c89a