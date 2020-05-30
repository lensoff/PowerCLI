#Installing
Install-Module Posh-SSH

#########################
#	Some Usage Examples	#
#########################
# 1	#
#####
Get-Command -Module Posh-SSH
New-SSHSession -ComputerName "thomasmaurer.azure.cloudapp.net" -Credential (Get-Credential root)
New-SSHSession -ComputerName "thomasmaurer.azure.cloudapp.net" -User "" -Password ""
Invoke-SSHCommand -Index 0 -Command "uname"
Get-SSHSession
Invoke-SSHCommand -SessionId 0 -Command cut -d: -f1 /etc/passwd

#https://www.thomasmaurer.ch/2016/04/using-ssh-with-powershell/
#https://sid-500.com/2017/09/03/powershell-use-ssh-to-connect-to-remote-hosts-posh-ssh/

#########
#	II	#
#########
New-SSHSession -ComputerName $fqdn -Credential (Get-Credential root)
$sessionID = Get-SSHSession
Invoke-SSHCommand -SessionId $sessionID.SessionId -Command "esxcli network ip dns search list && esxcli network ip interface list"
Remove-SSHSession -SessionId $sessionID.SessionId -Verbose

#https://kb.paessler.com/en/topic/71815-using-powershell-for-ssh-script-execution

#########
#	III	#
#########
$fqdn = "zbx-db-node1.echd.ru"
$Username = ""
$Password = ""
Remove-SSHTrustedHost $fqdn | Out-Null

$SecPasswd = ConvertTo-SecureString $Password -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential ($Username, $secpasswd)
$command0 = "cat /etc/centos-release"
$command1 = "uname -a"
$Session = New-SSHSession -Computername $fqdn -Credential $Credentials -AcceptKey:$true
$Output0 = (Invoke-SSHCommand -SSHSession $Session -Command $Command0).Output
$Output1 = (Invoke-SSHCommand -SSHSession $Session -Command $Command1).Output
Write-Host $Output0
Write-Host $Output1
Remove-SSHSession -Name $Session | Out-Null

