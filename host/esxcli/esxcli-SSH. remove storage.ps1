#List datastores
esxcli storage filesystem list

#unmount the datastore

esxcli storage filesystem unmount -l LUN01
# esxcli storage filesystem unmount -u 4e414917-a8d75514-6bae-0019b9f1ecf4
# esxcli storage filesystem unmount -p /vmfs/volumes/4e414917-a8d75514-6bae-0019b9f1ecf4

#To verify that the datastore is unmounted, run this command
esxcli storage filesystem list

#show LUNs NAA_ID
esxcli storage vmfs extent list
#esxcli iscsi adapter target portal list

#To detach the device/LUN, run this command:
esxcli storage core device set --state=off -d NAA_ID

#To verify that the device is offline, run this command:
esxcli storage core device list -d NAA_ID

#To rescan all devices on the ESXi host, run this command:
esxcli storage core adapter rescan -a

#To list the permanently detached devices:
esxcli storage core device detached list

#To permanently remove the device configuration information from the system
esxcli storage core device detached remove -d NAA_ID

#http://www.vcloudnotes.com/2016/07/unmounting-lun-or-detaching-datastore.html
#http://myitoverview.blogspot.com/2015/01/how-to-delete-and-detach-iscsi-volumes.html

