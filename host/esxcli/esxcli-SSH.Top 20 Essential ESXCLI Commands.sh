#System related commands
esxcli system version get
esxcli system hostname get
esxcli system stats installtime get
esxcli system account list
esxcli system account add -d=”Altaro Guest” -i=”altaro” -p=”dsfewfewf*3!4404″ -c=”dsfewfewf*3!4404″
esxcli system maintenanceMode set –enable true
esxcli system shutdown reboot -d 10 -r “Patch Updates”
#Network related commands
esxcli network firewall get
esxcli network firewall set –enabled true | false
esxcli network firewall ruleset list | awk ‘$2 ==”true”‘
esxcli network ip interface ipv4 get
#Software related commands
esxcli software vib list
esxcli software vib update -d “/tmp/update.zip”
#Virtual Machine related commands
esxcli vm process list
esxcli vm process kill -w 69237 -t soft
#Storage related commands
esxcli storage vmfs extent list
esxcli storage filesystem list
#iSCSI related commands
esxcli iscsi software set –enabled true && esxcli iscsi software get
esxcli iscsi adapter param get -A vmhba65
#Available ESXCLI commands
esxcli esxcli command list

#https://www.altaro.com/vmware/top-20-esxcli-commands/
