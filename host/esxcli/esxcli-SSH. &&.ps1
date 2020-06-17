esxcli network ip dns search list && esxcli network ip interface list
#or
esxcli network ip interface remove -i vmk0 && esxcli network ip interface ipv4 set -i vmk1 -t static -I IP_ADDRESS -N 255.255.254.0