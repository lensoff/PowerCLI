esxcli network nic list

#https://communities.vmware.com/thread/543972

#0
Invoke-Item "d:\1\WinSCP\WinSCP.exe"

#1
$srv = "srv16-21.abc.abc"
$Username = "root"
$Password = ""
$SecPasswd = ConvertTo-SecureString $Password -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential ($Username, $secpasswd)
Set-SCPFile -ComputerName $srv -Credential $Credentials -RemotePath '/tmp/' -LocalFile 'd:\Lost Network Connectivity\esxi-sysinfo-snapshot.py' -AcceptKey:$true

cd /tmp/
chmod +x esxi-sysinfo-snapshot.py
./esxi-sysinfo-snapshot.py

#2
#Web GUI   --> Status Tab ---> Maintenance Tab  --> "Generate Sysdump File" или через CLI switch (config) # debug generate dump.

#3
esxcli software vib install -v "/tmp/nmst-4.14.0.105-1OEM.650.0.0.4598673.x86_64.vib"
esxcli software vib install -v "/tmp/mft-4.14.0.105-10EM-650.0.0.4598673.x86_64.vib"

cd /opt/mellanox/bin/
/opt/mellanox/bin/mst status

./mstdump mt4103_pci_cr0 > /tmp/mstdump-mt4103_pci_cr0.log
./mstdump mt4103_pci_cr1 > /tmp/mstdump-mt4103_pci_cr1.log

/opt/mellanox/bin/mstdump mt4103_pciconf0 > /tmp/mstdump1.log
/opt/mellanox/bin/mstdump mt4103_pci_cr0 > /tmp/mstdump2.log
/opt/mellanox/bin/mstdump mt4103_pciconf1 > /tmp/mstdump3.log
/opt/mellanox/bin/mstdump mt4103_pci_cr1 > /tmp/mstdump4.log

###########

/opt/mellanox/bin/flint -d mt4103_pci_cr0 q | grep 'PSID:'
/opt/mellanox/bin/flint -d mt4103_pci_cr1 q | grep 'PSID:'

############

/opt/mellanox/bin/flint -d mt4103_pciconf0 q | grep 'FW Version:'
/opt/mellanox/bin/flint -d mt4103_pci_cr0 q | grep 'FW Version:'
/opt/mellanox/bin/flint -d mt4103_pciconf1 q | grep 'FW Version:'
/opt/mellanox/bin/flint -d mt4103_pci_cr1 q | grep 'FW Version:'

###########

/opt/mellanox/bin/mst start
/opt/mellanox/bin/mst status

#/opt/mellanox/bin/flint -d mt4103_pciconf0 -i /tmp/fw-ConnectX3Pro-rel-2_36_5000-MCX312C-XCC_Ax-FlexBoot-3.4.718.bin burn
#/opt/mellanox/bin/flint -d mt4103_pciconf1 -i /tmp/fw-ConnectX3Pro-rel-2_36_5000-MCX312C-XCC_Ax-FlexBoot-3.4.718.bin burn
echo 'y' | /opt/mellanox/bin/flint -d mt4103_pci_cr0 -i /tmp/fw-ConnectX3Pro-rel-2_36_5000-MCX312C-XCC_Ax-FlexBoot-3.4.718.bin burn
echo 'y' | /opt/mellanox/bin/flint -d mt4103_pci_cr1 -i /tmp/fw-ConnectX3Pro-rel-2_36_5000-MCX312C-XCC_Ax-FlexBoot-3.4.718.bin burn

/opt/mellanox/bin/flint -d /dev/mst/mt4099_pci_cr0 -i fw-ConnectX3Pro-rel-2_36_5000-MCX312C-XCC_Ax-FlexBoot-3.4.718.bin burn
mt4103_pciconf0
mt4103_pci_cr0
mt4103_pciconf1
mt4103_pci_cr1

#4
vm-support -w /vmfs/volumes/VMCL09-ST23-02-L103-g

#5 vCenter logs
shell
vc-support -l
#https://kb.vmware.com/s/article/1011641#Topic%202%20CLI