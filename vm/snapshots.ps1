#Show snapshots
$vm | get-snapshot | ft vm,created,name,SizeGB -auto
get-snapshot -vm $vm

get-vm | get-snapshot | select VM,Name,Description,
PowerState,Quiesced,Created,Parent,
@{Name="Age";Expression={(Get-Date) - $_.Created }},
@{Name="SizeMB";Expression={[math]::Round($_.SizeMB,2)}} |
Sort VM,Created

#Creating snapshots
$vm | new-snapshot -Name "Demo" -Description "Demo snapshot" -Quiesce -Memory
#Restore from the snapshot 
$vm | set-vm -Snapshot "before"
#Remove the snapshot
$vm | remove-snapshot -Name "before"
$vm | get-snapshot -name "before" | remove-snapshot -RunAsync -confirm:$false #–RemoveChildren
get-snapshot -vm * | remove-snapshot -RemoveChildren -RunAsync -confirm:$false
# Consolidation
Get-VM | Where-Object {$_.Extensiondata.Runtime.ConsolidationNeeded}
Get-VM | Where-Object {$_.Extensiondata.Runtime.ConsolidationNeeded} | foreach {$_.ExtensionData.ConsolidateVMDisks_Task()}

##################
#	Example
##################

$vmName = "ma-node1","my-node1","my-node2"
$snapName = "Return-Point"

get-vm $vmName | new-snapshot -Name "Return-Point" -Description "Before MaxScale" -Quiesce

foreach($vm in $vmName){
	$snap = Get-Snapshot -VM $vm -Name $snapName
	Set-VM -VM $vm -Snapshot $snap -Confirm:$false
}

##################
#	Snapshots Report
##################

$table = foreach ( $vm in get-vm | sort ) {
    [Array] $vmSnapshotList = @( Get-Snapshot -VM $vm );

    foreach ( $snapshotItem in $vmSnapshotList ) {
        $vmProvisionedSpaceGB = [Math]::Round( $vm.ProvisionedSpaceGB, 2 );
        $vmUsedSpaceGB        = [Math]::Round( $vm.UsedSpaceGB,        2 );
        $snapshotSizeGB       = [Math]::Round( $snapshotItem.SizeGB,       2 );
        $snapshotAgeDays      = ((Get-Date) - $snapshotItem.Created).Days;

        $output = New-Object -TypeName PSObject;

        $output | Add-Member -MemberType NoteProperty -Name "VM"                 -Value $vm;
        $output | Add-Member -MemberType NoteProperty -Name "Name"               -Value $snapshotItem.Name;
        $output | Add-Member -MemberType NoteProperty -Name "Description"        -Value $snapshotItem.Description;
        $output | Add-Member -MemberType NoteProperty -Name "Created"            -Value $snapshotItem.Created;
        $output | Add-Member -MemberType NoteProperty -Name "AgeDays"            -Value $snapshotAgeDays;
        $output | Add-Member -MemberType NoteProperty -Name "ParentSnapshot"     -Value $snapshotItem.ParentSnapshot.Name;
        $output | Add-Member -MemberType NoteProperty -Name "IsCurrentSnapshot"  -Value $snapshotItem.IsCurrent;
        $output | Add-Member -MemberType NoteProperty -Name "SnapshotSizeGB"     -Value $snapshotSizeGB;
        $output | Add-Member -MemberType NoteProperty -Name "ProvisionedSpaceGB" -Value $vmProvisionedSpaceGB;
        $output | Add-Member -MemberType NoteProperty -Name "UsedSpaceGB"        -Value $vmUsedSpaceGB;
        $output | Add-Member -MemberType NoteProperty -Name "PowerState"         -Value $snapshotItem.PowerState;

        $output;
    }
} 
$table | select VM,Name,Description,Created,AgeDays,ParentSnapshot,IsCurrentSnapshot,SnapshotSizeGB,ProvisionedSpaceGB,UsedSpaceGB,PowerState | Export-Csv -Path "D:\0-SSS.csv" -NoTypeInformation -UseCulture -Encoding UTF8
# https://github.com/vmware/PowerCLI-Example-Scripts/blob/master/PowerActions/VM-Snapshot-Report.ps1