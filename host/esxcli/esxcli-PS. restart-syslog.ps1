$vmhost = Get-VMHost "srv14-16.abc.abc"
$esxcli = Get-EsxCli -VMHost $vmhost
$esxcli.system.syslog.reload()

$esxcli = Get-EsxCli -VMHost $vmhost -V2
$esxcli.system.syslog.reload.invoke()