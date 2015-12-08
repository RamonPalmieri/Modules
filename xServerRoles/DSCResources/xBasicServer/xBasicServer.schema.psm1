Configuration xBasicServer
{

<#
    xBasicServer BasicSettings
    {
        Server = $Server
        VDCDomain = $VDCDomain
        VDCDomainCred = $VDCDomainCred
        TimeZone = $TimeZone
    }

#>

    param
    (
    
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$Server,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$VDCDomain,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.PSCredential]$VDCDomainCred,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$TimeZone

    )

    Import-DscResource -Module xTimeZone
    Import-DscResource -Module xRemoteDesktopAdmin, xNetworking
    Import-DscResource -Module xComputerManagement

    xComputer JoinDomain
    {
        Name          = $Server
        DomainName    = $VDCDomain
        Credential    = $VDCDomainCred
    }
 
    # Start TimeZone Settings
    xTimeZone TimeZone
    {
        TimeZone = $TimeZone
    }

    # Enable remote Desktop
    xRemoteDesktopAdmin RemoteDesktopSettings
    {
        Ensure = 'Present'
        UserAuthentication = 'Secure'
    }

    xFirewall AllowRDP
    {
        Name = 'DSC - Remote Desktop Admin Connections'
        DisplayGroup = "Remote Desktop"
        Ensure = 'Present'
        State = 'Enabled'
        Access = 'Allow'
        Profile = 'Domain'
    }

}
