Configuration xFirstDomainController
{

 <#
    xFirstDomainController MyFirstDC
    {
        VDCDomain = $VDCDomain
        vDCDomainCred = $vDCDomainCred
        vDVsafemodeAdminCred = $vDVsafemodeAdminCred
        CloudDomain = $CloudDomain
        CloudDomainCreds = $CloudDomainCreds
        CloudDNS = $CloudDNS
    }

#>

    param
    (
    
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$VDCDomain,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.PSCredential]$VDCDomainCred,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.PSCredential]$vDVsafemodeAdminCred,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$CloudDomain,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.PSCredential]$CloudDomainCreds,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$CloudDNS

    )

    Import-DscResource -Module xActiveDirectory
    Import-DscResource -Module xNonStop
   
        # Make DC
        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
        }

        WindowsFeature RSAT-ADDS
        {
            Ensure = "Present"
            Name = "RSAT-ADDS"
        }

        xADDomain FirstForestDomain
        {
            DomainName = $VDCDomain
            SafemodeAdministratorPassword = $vDVsafemodeAdminCred
            DomainAdministratorCredential = $vDCDomainCred
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        xADDomainTrust trust
        {
            Ensure                              = 'Present'
            SourceDomainName                    = $VDCDomain
            TargetDomainName                    = $CloudDomain
            TargetDomainAdministratorCredential = $CloudDomainCreds
            TrustDirection                      = 'Outbound'
            TrustType                           = 'External'
            DependsOn = "[xADDomain]FirstForestDomain"
        }

        xNonStop ConditionalForward
        {
            ForwarderName = $CloudDomain
            MasterServer = $CloudDNS
            Ensure = 'Present'
       }
}
