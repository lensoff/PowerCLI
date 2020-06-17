# https://kb.vmware.com/s/article/1027206
# Obtaining Host Bus adapter driver and firmware information

esxcfg-scsidevs -a

vmkload_mod -s lpfc | grep Version
for a in $(esxcfg-scsidevs -a | grep Emulex | awk '{print $2}') ;do vmkload_mod -s $a | grep -i version ;done

vmkchdev -l | grep vmhba1
for a in $(esxcfg-scsidevs -a | grep Emulex | awk '{print $1}') ;do vmkchdev -l | grep $a ;done

000:16.0 1000:0030 15ad:1976 vmkernel vmhba1

#In this example, the values are:

    VID = 1000
    DID = 0030
    SVID = 15ad
    SDID = 1976 

0000:84:00.0 10df:e200 10df:e277 vmkernel vmhba4
VID = 10df
DID = e200
SVID = 10df
SDID = e277

https://www.vmware.com/resources/compatibility/search.php?deviceCategory=io
	
vmware -v

# Obtaining Network card driver and firmware information

esxcfg-nics -l
esxcli network nic list

esxcli network nic get -n vmnic#

#########
esxcli storage san fc list

[root@hua01-01:~] for a in $(esxcfg-scsidevs -a | grep Emulex | awk '{print $2}') ;do vmkload_mod -s $a | grep -i version ;done
 Version: 10.2.309.8-2vmw.600.0.0.2494585
 Version: 10.2.309.8-2vmw.600.0.0.2494585
 Version: 10.2.309.8-2vmw.600.0.0.2494585
 Version: 10.2.309.8-2vmw.600.0.0.2494585
 Version: 10.2.309.8-2vmw.600.0.0.2494585
 Version: 10.2.309.8-2vmw.600.0.0.2494585
[root@hua01-01:~]
[root@hua01-01:~]
[root@hua01-01:~]
[root@hua01-01:~]
[root@hua01-01:~] for a in $(esxcfg-scsidevs -a | grep Emulex | awk '{print $1}') ;do vmkchdev -l | grep $a ;done
0000:05:00.2 19a2:0714 10df:e780 vmkernel vmhba2
0000:05:00.3 19a2:0714 10df:e780 vmkernel vmhba3
0000:84:00.0 10df:e200 10df:e277 vmkernel vmhba4
0000:84:00.1 10df:e200 10df:e277 vmkernel vmhba5
0000:04:00.2 19a2:0714 10df:e780 vmkernel vmhba6
0000:04:00.3 19a2:0714 10df:e780 vmkernel vmhba7
[root@hua01-01:~] esxcli network nic list
Name    PCI Device    Driver  Admin Status  Link Status  Speed  Duplex  MAC Address         MTU  Description
------  ------------  ------  ------------  -----------  -----  ------  -----------------  ----  -------------------------------------------------
vmnic0  0000:05:00.0  elxnet  Up            Up           10000  Full    f8:75:88:89:3c:ce  9000  Emulex Corporation Emulex OneConnect OCe11100 NIC
vmnic1  0000:05:00.1  elxnet  Up            Up           10000  Full    f8:75:88:89:3c:d2  9000  Emulex Corporation Emulex OneConnect OCe11100 NIC
vmnic2  0000:04:00.0  elxnet  Up            Up           10000  Full    f8:75:88:89:3c:c6  1500  Emulex Corporation Emulex OneConnect OCe11100 NIC
vmnic3  0000:04:00.1  elxnet  Up            Up           10000  Full    f8:75:88:89:3c:ca  1500  Emulex Corporation Emulex OneConnect OCe11100 NIC
[root@hua01-01:~] esxcli network nic get -n vmnic0
   Advertised Auto Negotiation: true
   Advertised Link Modes: 10000baseT/Full
   Auto Negotiation: false
   Cable Type:
   Current Message Level: 4631
   Driver Info:
         Bus Info: 0000:05:00:0
         Driver: elxnet
         Firmware Version: 10.2.615.0
         Version: 10.2.309.6v
   Link Detected: true
   Link Status: Up
   Name: vmnic0
   PHYAddress: 0
   Pause Autonegotiate: false
   Pause RX: true
   Pause TX: true
   Supported Ports:
   Supports Auto Negotiation: true
   Supports Pause: true
   Supports Wakeon: true
   Transceiver:
   Virtual Address: 00:50:56:58:06:a1
   Wakeon: MagicPacket(tm)
[root@hua01-01:~] esxcli network nic get -n vmnic3
   Advertised Auto Negotiation: true
   Advertised Link Modes: 10000baseT/Full
   Auto Negotiation: false
   Cable Type:
   Current Message Level: 4631
   Driver Info:
         Bus Info: 0000:04:00:1
         Driver: elxnet
         Firmware Version: 10.2.615.0
         Version: 10.2.309.6v
   Link Detected: true
   Link Status: Up
   Name: vmnic3
   PHYAddress: 0
   Pause Autonegotiate: false
   Pause RX: true
   Pause TX: true
   Supported Ports:
   Supports Auto Negotiation: true
   Supports Pause: true
   Supports Wakeon: true
   Transceiver:
   Virtual Address: 00:50:56:5a:de:d2
   Wakeon: MagicPacket(tm)
[root@hua01-01:~] esxcfg-scsidevs -a | grep Emulex
vmhba2  lpfc              link-n/a  fc.2000f87588893ccf:1000f87588893ccf    (0000:05:00.2) ServerEngines Corporation Emulex OneConnect OCe11100 FCoE Initiator
vmhba3  lpfc              link-n/a  fc.2000f87588893cd3:1000f87588893cd3    (0000:05:00.3) ServerEngines Corporation Emulex OneConnect OCe11100 FCoE Initiator
vmhba4  lpfc              link-up   fc.20002c55d3b65ab8:10002c55d3b65ab8    (0000:84:00.0) Emulex Corporation Emulex LightPulse LPe16000 PCIe Fibre Channel Adapter
vmhba5  lpfc              link-up   fc.20002c55d3b65ab9:10002c55d3b65ab9    (0000:84:00.1) Emulex Corporation Emulex LightPulse LPe16000 PCIe Fibre Channel Adapter
vmhba6  lpfc              link-n/a  fc.2000f87588893cc7:1000f87588893cc7    (0000:04:00.2) ServerEngines Corporation Emulex OneConnect OCe11100 FCoE Initiator
vmhba7  lpfc              link-n/a  fc.2000f87588893ccb:1000f87588893ccb    (0000:04:00.3) ServerEngines Corporation Emulex OneConnect OCe11100 FCoE Initiator

VMware ESXi 6.0.0 build-6921384