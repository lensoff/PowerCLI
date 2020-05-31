Get-VIPermission

$Osk = Get-Folder -Name Osaka
New-VIPermission -Entity $Osk -Principal ‘username’ -Role ‘role to assign’ -Propagate:$false

########################

$folderName = 'MyFolder'

Get-Folder -Name $folderName | Get-VM |
New-VIPermission -Principal domain\group -Role YourRole

########################

$account = Get-VIAccount -Id "zbxrestarter" -Domain "ECHD"
Get-Cluster VMCL* | New-VIPermission -Role 'Admin' -Principal $account

#########################
#	Add a new role
#########################
#1 Get the privileges of the Readonly role.
$readOnlyPrivileges = Get-VIPrivilege -Role Readonly

#2 Create a new role with custom privileges.
$vFenceRole = New-VIRole -Privilege $readOnlyPrivileges -Name vFenceRole

Get-VIPrivilege | select-string -pattern "Power"

#3 Add the PowerOn and Poweroff privileges to the new role.
$powerOnPrivileges = Get-VIPrivilege -Id "VirtualMachine.Interact.PowerOn"
$powerOnPrivileges = Get-VIPrivilege -Id "VirtualMachine.Interact.PowerOff"
$vFenceRole = Set-VIRole –Role $vFenceRole –AddPrivilege $powerOnPrivileges
$vFenceRole = Set-VIRole –Role $vFenceRole –AddPrivilege $powerOffPrivileges

#or (Example)
New-VIRole -Name “XYZ” -Privilege (Get-VIPrivilege -Id VirtualMachine.Interact.PowerOn,VirtualMachine.Interact.PowerOff,VirtualMachine.Config.AddNewDisk,VirtualMachine.Config.AdvancedConfig)
https://defaultreasoning.com/2016/04/26/powercli-basics/

$VAppPowerOnPrivileges = Get-VIPrivilege -Id "VApp.PowerOn"
$VAppPowerOffPrivileges = Get-VIPrivilege -Id "VApp.PowerOff"
Set-VIRole –Role vFenceRole –RemovePrivilege $VAppPowerOnPrivileges
Set-VIRole –Role vFenceRole –RemovePrivilege $VAppPowerOffPrivileges

Get-VIrole -Name "vFenceRole" | fl
(Get-VIRole -Name vFenceRole).PrivilegeList
(Get-VIRole -Name vFenceRole).PrivilegeList.Count

#4 Create a permission and apply it to a vSphere root object.
$rootFolder = Get-Folder -NoRecursion
$permission1 = New-VIPermission -Entity $rootFolder -Principal "user" -Role readonly -Propagate
#The Principal parameter accepts both local and domain users and groups if the vCenter Server system is joined in AD.

#5 Update the new permission with the custom role.
$permission1 = Set-VIPermission -Permission $permission1 -Role $vFenceRole
#You created a new role and assigned permissions to a user.

#http://www.thevirtualist.org/roles-privileges-permissions-powercli/
#https://szumigalski.com/2017/03/29/manage-vcenter-permissions-with-vmware-powercli/

##########
## Adding roles with privileges from powercli
#############
$privs_for_role=@(
'System.Anonymous',
'System.View',
'System.Read')
New-VIRole -Name custom_role1 -Privilege (Get-VIPrivilege -id $privs_for_role)

############################

New-VIRole -Name 'vFenceRole' -Privilege (Get-VIPrivilege -Id VirtualMachine.Interact.PowerOn,VirtualMachine.Interact.PowerOff,System.Anonymous,System.View)

Administration - Users - Add
Administration - Global Permissions - Add Permission