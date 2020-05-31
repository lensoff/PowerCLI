function Get-VMCPSettings {
<#
 	
	.NOTES
	===========================================================================
	 Created on:   	10/27/2015 9:25 PM
	 Created by:   	Brian Graf
     Twitter:       @vBrianGraf
     VMware Blog:   blogs.vmware.com/powercli
     Personal Blog: www.vtagion.com
     Modified on:  	10/11/2016
	 Modified by:  	Erwan Quélin
     Twitter:       @erwanquelin
     Github:        https://github.com/equelin    
	===========================================================================
	.DESCRIPTION
    This function will allow users to view the VMCP settings for their clusters
    .PARAMETER Cluster
    Cluster Name or Object
    .PARAMETER Server
    vCenter server object
    .EXAMPLE
    Get-VMCPSettings
    This will show you the VMCP settings for all the clusters
    .EXAMPLE
    Get-VMCPSettings -cluster LAB-CL
    This will show you the VMCP settings of your cluster
    .EXAMPLE
    Get-VMCPSettings -cluster (Get-Cluster Lab-CL)
    This will show you the VMCP settings of your cluster
    .EXAMPLE
    Get-Cluster | Get-VMCPSettings
    This will show you the VMCP settings for all the clusters
#>
    [CmdletBinding()]
    param
    (
    [Parameter(Mandatory=$False,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True,
        HelpMessage='What is the Cluster Name?')]
    $cluster = (Get-Cluster -Server $Server),

    [Parameter(Mandatory=$False)]
    [VMware.VimAutomation.Types.VIServer[]]$Server = $global:DefaultVIServers
    )

    Process {

        Foreach ($Clus in $Cluster) {

            Write-Verbose "Processing Cluster $($Clus.Name)"

            # Determine input and convert to ClusterImpl object
            Switch ($Clus.GetType().Name)
            {
                "string" {$CL = Get-Cluster $Clus  -Server $Server -ErrorAction SilentlyContinue}
                "ClusterImpl" {$CL = $Clus}
            }

            If ($CL) {
                # Work with the Cluster View
                $ClusterMod = Get-View -Id "ClusterComputeResource-$($CL.ExtensionData.MoRef.Value)" -Server $Server

                # Create Hashtable with desired properties to return
                $properties = [ordered]@{
                    'Cluster' = $ClusterMod.Name;
                    'VMCP Status' = $clustermod.Configuration.DasConfig.VmComponentProtecting;
                    'Protection For APD' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmStorageProtectionForAPD;
                    'APD Timeout Enabled' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.EnableAPDTimeoutForHosts;
                    'APD Timeout (Seconds)' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmTerminateDelayForAPDSec;
                    'Reaction on APD Cleared' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmReactionOnAPDCleared;
                    'Protection For PDL' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmStorageProtectionForPDL
                }

                # Create PSObject with the Hashtable
                $object = New-Object -TypeName PSObject -Prop $properties

                # Show object
                $object
            }
        }
    }
}
