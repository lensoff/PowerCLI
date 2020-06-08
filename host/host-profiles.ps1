#New-VMHostProfile
#Apply-VMHostProfile
#Test-VMHostProfileCompliance

#Create a Host Profile from the CLI
New-VMHostProfile -Name SpecificNameHere -ReferenceHost $RefHost -Description "This is for testing compliance in the first vCenter"
Get-VMHostProfile -Name SpecificNameHere

#Attach the Host Profile to a Cluster and/or specific hosts by using these commands
Invoke-VMHostProfile -AssociateOnly -Entity $cluster -Profile $profile
Get-VMHost | Invoke-VMHostProfile -AssociateOnly -profile $profile

#Test compliance against the hosts
Test-VMHostProfileCompliance -VMHost *
#Test compliance against the profile specified
Test-VMHostProfileCompliance -Profile SpecificNameHere

##############
#	All-in-One
##############

$vmhost | set-VMHost -State Maintenance
#Attach the Host Profile and then test compliance
$vmhost | Invoke-VMHostProfile -AssociateOnly -Profile iscsiTestCL01 -Confirm:$false
$vmhost | Test-VMHostProfileCompliance
#Apply the Host Profile
$vmhost | Apply-VMHostProfile -Confirm:$false
$vmhost | set-VMHost -State Connected

#export a copy of a HP
Export-VMHostProfile c:\ -Profile SpecificNameHere

#https://ifitisnotbroken.wordpress.com/2017/12/22/host-profiles-and-the-cli-part-1/
#https://ifitisnotbroken.wordpress.com/2017/12/28/host-profiles-and-the-cli-part-2/

#########
Get-VMHostProfile
Get-VMHostProfile | Remove-VMHostProfile -Confirm:$false
New-VMHostProfile -Name iscsiTestCL01 -ReferenceHost ( get-cluster TestCL01 | get-vmhost | where { $_.ConnectionState -eq "Connected" } | sort | select -first 1 ) -Description "A host profile with cluster's iSCSI targets"
Get-VMHost srv09-02.abc.abc | Invoke-VMHostProfile -AssociateOnly -Profile iscsiTestCL01 -Confirm:$false
Get-VMHost srv09-02.abc.abc | Test-VMHostProfileCompliance | fl
Get-VMHost srv09-02.abc.abc | Apply-VMHostProfile -Confirm:$false
