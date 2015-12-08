Configuration xSQLClusterNode
{

    param
    (	
        [parameter(Mandatory)]
        [string] $ClusterName,

        [parameter(Mandatory)]
        [string] $ClusterIPAddress,
        
        [parameter(Mandatory)]
        [PSCredential] $DomainCred
    )

        Import-DSCResource -Module xFailOverCluster
        
        WindowsFeature FailoverFeature
        {
            Ensure = "Present"
            Name      = "Failover-clustering"
        }

        WindowsFeature RSATClusteringPowerShell
        {
            Ensure = "Present"
            Name   = "RSAT-Clustering-PowerShell"   

            DependsOn = "[WindowsFeature]FailoverFeature"
        }

        WindowsFeature RSATClusteringCmdInterface
        {
            Ensure = "Present"
            Name   = "RSAT-Clustering-CmdInterface"

            DependsOn = "[WindowsFeature]RSATClusteringPowerShell"
        }

        xWaitForCluster waitForCluster
        {
            Name = $ClusterName
            RetryIntervalSec = 10
            RetryCount = 60

            DependsOn = “[WindowsFeature]RSATClusteringCmdInterface” 
        }

        WindowsFeature RSATClusteringmgmt
        {
            Ensure = "Present"
            Name   = "RSAT-Clustering-mgmt"
        }

        xCluster joinCluster
        {
            Name = $ClusterName
            StaticIPAddress = $ClusterIPAddress
            DomainAdministratorCredential = $DomainCred

            DependsOn = "[xWaitForCluster]waitForCluster"
        }  

}
