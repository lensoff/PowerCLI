#Set-SdrsCluster
New-DatastoreCluster -Name 'MyDatastoreCluster' -Location 'MyDatacenter'

Set-DatastoreCluster -DatastoreCluster MyDatastoreCluster1 -Name 'MyDatastoreCluster2'
Set-DatastoreCluster -DatastoreCluster MyDatastoreCluster -IOLatencyThresholdMillisecond 5
Set-DatastoreCluster -DatastoreCluster MyDatastoreCluster - SdrsAutomationLevel FullyAutomated

#Parameters
#Simple ParameterSets
#Set Default VM affinity
Get-DatastoreCluster $DatastoreClusterName | Set-SdrsCluster –DefaultIntraVmAffinity DistributeAcrossDatastores
Get-DatastoreCluster $DatastoreClusterName | Set-SdrsCluster –DefaultIntraVmAffinity KeepTogether
#Turn ON/OFF vSphere Storage DRS
Get-DatastoreCluster $DatastoreClusterName | Set-SdrsCluster –TurnOnSDRS:$true
Get-DatastoreCluster $DatastoreClusterName | Set-SdrsCluster –TurnOnSDRS:$false
#Set Storage DRS Automation level
Get-DatastoreCluster $DatastoreClusterName | Set-SdrsCluster –AutomationLevel FullyAutomated
Get-DatastoreCluster $DatastoreClusterName | Set-SdrsCluster –AutomationLevel ManualMode

#Complex ParameterSets
#Set SDRS Runtime Rules that include: I/O Metrics, Thresholds and Advanced Options
Get-DatastoreCluster $DatastoreClusterName | Set-SdrsCluster –EnableIOMetric:$true

Get-DatastoreCluster $DatastoreClusterName | Set-SdrsCluster –EnableIOMetric:$true -UtilizedSpace 90 –IOLatency 10 –MinSpaceUtilizationDifference 20 –CheckImbalanceEveryMin 43200 –IOImbalanceThreshold 20

#Set Configuration Parameters
Get-DatastoreCluster $DatastoreClusterName | Set-SdrsCluster –Option $Option –Value $Value
Get-DatastoreCluster | Set-SdrsCluster -Option IgnoreAffinityRulesForMaintenance -Value 1

#The -ShowBeforeState switch
Get-DatastoreCluster | Set-SdrsCluster -ShowBeforeState –AutomationLevel FullyAutomated
Get-DatastoreCluster | Set-SdrsCluster -ShowBeforeState –EnableIOMetric:$true
Get-DatastoreCluster | Set-SdrsCluster -ShowBeforeState -Option IgnoreAffinityRulesForMaintenance -Value 1

#Get-SdrsCluster
#Overall SDRS cluster settings
Get-DatastoreCluster | Get-SdrsCluster
Get-DatastoreCluster -Location $DatacenterName | Get-SdrsCluster
Get-Datacenter $DatacenterName | Get-DatastoreCluster PROD* | Get-SdrsCluster

#VM Overrides
Get-DatastoreCluster | Get-SdrsCluster –VMOverrides
Get-DatastoreCluster | Get-SdrsCluster -VMSettings

# https://ps1code.com/2017/08/16/sdrs-powercli-part1/