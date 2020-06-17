##################################################
#	Configure PowerShell Execution Policy
##################################################
Set-ExecutionPolicy RemoteSigned

############################################
#	Install and configure the module
############################################
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name VMware.PowerCLI -Scope CurrentUser
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false

############################
#	Optional parameter
############################
Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Confirm:$false

############################
#	Another optional parameter
############################
(Get-PowerCLIConfiguration -Scope Session).WebOperationTimeoutSeconds #a default value (300)
Set-PowerCLIConfiguration -Scope User -WebOperationTimeoutSeconds 1800000 -Confirm:$false
#https://pubs.vmware.com/vsphere-51/index.jsp?topic=%2Fcom.vmware.powercli.ug.doc%2FGUID-4F61FB46-5917-4979-88BB-DF5649167CF3.html

############################################
#	Update the module
############################################
Update-Module -Name VMware.PowerCLI -Confirm:$false

#######################
#	Other Commands
#######################
Find-Module -Name VMware.PowerCLI

Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope User
Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope Session
Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope AllUsers

Get-PowerCLIConfiguration

#https://blogs.vmware.com/PowerCLI/2017/04/powercli-install-process-powershell-gallery.html
