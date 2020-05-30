#Find-Module -Name VMware.PowerCLI
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name VMware.PowerCLI -Scope CurrentUser #-AllowClobber

#Update-Module -Name VMware.PowerCLI -Confirm:$false

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false

Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Confirm:$false
#Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope User
#Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope Session
#Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope AllUsers

Get-PowerCLIConfiguration
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore



#https://blogs.vmware.com/PowerCLI/2017/04/powercli-install-process-powershell-gallery.html
