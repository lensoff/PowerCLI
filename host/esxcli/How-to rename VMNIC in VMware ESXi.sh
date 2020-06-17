#https://www.vladan.fr/how-to-rename-vmnic-in-vmware-esxi/
cp /etc/vmware/esx.conf /etc/vmware/esx.conf.old
esxcfg-nics -l

#step-by step for those struggling with putty:

    #Open Putty and type 
	cd /etc/vmware
    #Then type 
	vi esx.conf
    #scroll further down and untill you see Dev/ids which follow with a =vmnic#
    #Type i  (for Insert)
    #Then you can go the VMnic you wish to modify and use Del or Backspace to modify the name
    #Hit “ESC” key
    #Type “:wq”  to quit.
    #Type “reboot” to reboot the host
