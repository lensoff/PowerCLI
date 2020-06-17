esxcli vm process list | grep 'Display Name'
#esxcli vm process kill -type=soft - world-id=yyyyy
esxcli vm process kill -t=soft -w=
#-type=xxxx use: soft, hard or force
#http://www.running-system.com/kill-power-virtual-machine-using-esxcli-command/

#List the inventory ID of the virtual machine
vim-cmd vmsvc/getallvms
#Check the power state of the virtual machine
vim-cmd vmsvc/power.getstate <vmid>
#Power-on the virtual machine
vim-cmd vmsvc/power.on <vmid>
#Shutdown the virtual machine
vim-cmd vmsvc/power.shutdown VMID
#or
vim-cmd vmsvc/power.off VMID