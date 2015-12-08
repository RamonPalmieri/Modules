
Configuration xSQLCluster
{

<#
Beschrijving SQL Cluster
1 NIC voor client access
1 NIC voor iSCSI Disk

Shared Storage
Quorum Disk?


#>

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
        Import-DscResource -Module xCMCCustoms
        Import-DscResource -Module xConfigNIC


        # Start iSCSI Service
        Service MSiSCSI
        {
            Name = 'MSiSCSI'
            StartupType = 'Automatic'
            State = 'Running'
        }


        WindowsFeature FailoverFeature
        {
            Ensure = "Present"
            Name   = "Failover-clustering"
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

        WindowsFeature RSATClusteringmgmt
        {
            Ensure = "Present"
            Name   = "RSAT-Clustering-mgmt"
        }


        # Voor nu voor de file server testcluster Install-WindowsFeature FS-FileServer
        WindowsFeature FS-FileServer
        {
            Ensure = "Present"
            Name   = "FS-FileServer"
        }

        WindowsFeature RSAT-File-Services
        {
            Ensure = "Present"
            Name   = "RSAT-File-Services"
        }

        WindowsFeature RSAT-CoreFile-Mgmt
        {
            Ensure = "Present"
            Name   = "RSAT-CoreFile-Mgmt"
        }

        # Voor nu.....


        xConfigNIC StorageNIC
        {
            MACAddress = '00-50-56-87-de-87'
		    Mode = 'Static'
		    IPAddress = '192.168.80.185'
		    Netmask = '24'
		    Alias = 'StorageDSC'
            DependsOn = '[Service]MSiSCSI'
        }

        xCMCCustoms LUN01
        {
            TargetPortalAddress = '192.168.80.6'
            NodeAddress = 'iqn.2000-01.com.synology:nas3.target01.381d263ff5'
            IsPersistent = $true
            AuthenticationType = 'ONEWAYCHAP'
            CHAPUserName = 'chappie'
            CHAPSecret = 'chappieextra'
            DriveOnline = $False
            DependsOn = "[xConfigNIC]StorageNIC"
        }

        xCMCCustoms LUN03
        {
            TargetPortalAddress = '192.168.80.6'
            NodeAddress = 'iqn.2000-01.com.synology:nas3.target03.381d263ff5'
            IsPersistent = $true
            AuthenticationType = 'ONEWAYCHAP'
            CHAPUserName = 'chappie'
            CHAPSecret = 'chappieextra'
            DriveOnline = $False
            DependsOn = "[xConfigNIC]StorageNIC"
        }

        xCMCCustoms QuorumDisk
        {
            TargetPortalAddress = '192.168.80.6'
            NodeAddress = 'iqn.2000-01.com.synology:nas3.target02.381d263ff5'
            IsPersistent = $true
            AuthenticationType = 'ONEWAYCHAP'
            CHAPUserName = 'chappie'
            CHAPSecret = 'chappieextra'
            DriveOnline = $False
            DependsOn = "[xConfigNIC]StorageNIC"
        }

        # Wanneer je een cluster weg gooit, moet je misschien ook AD en DNS cleanen.
        # testen of dit zo is, of voor de demo steeds andere naam en IP nemen
        xCluster ensureCreated
        {
            Name = $ClusterName
            StaticIPAddress = $ClusterIPAddress
            DomainAdministratorCredential = $DomainCred
            DependsOn = “[WindowsFeature]FailoverFeature”
       } 

}
