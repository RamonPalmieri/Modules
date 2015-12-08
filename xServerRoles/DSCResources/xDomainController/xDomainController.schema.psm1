Configuration xDomainController
{

 <#
    xDomainController DC
    {
        VDCDomain = $VDCDomain
        vDCDomainCred = $vDCDomainCred
        vDVsafemodeAdminCred = $vDVsafemodeAdminCred
        RetryCount = $RetryCount
        RetryIntervalSec = $RetryIntervalSec
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
    [String]$RetryCount,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$RetryIntervalSec

    )

    Import-DscResource -Module xActiveDirectory


        # Domain Controller Install
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

        xWaitForADDomain DscForestWait 
        { 
            DomainName = $VDCDomain
            DomainUserCredential = $VDCDomainCred 
            RetryCount = $RetryCount 
            RetryIntervalSec = $RetryIntervalSec 
            DependsOn = "[WindowsFeature]ADDSInstall" 
        } 
 
        xADDomainController SecondDC 
        { 
            DomainName = $VDCDomain 
            DomainAdministratorCredential = $VDCDomainCred 
            SafemodeAdministratorPassword = $vDVsafemodeAdminCred 
            DependsOn = "[xWaitForADDomain]DscForestWait" 
        }


}
