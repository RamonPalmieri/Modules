Configuration xDefaultServer
{   
    Import-DscResource -Module xTimeZone
    Import-DscResource -Module xRemoteDesktopAdmin, xNetworking

    # Start TimeZone Settings
    xTimeZone TimeZone
    {
        TimeZone = "W. Europe Standard Time"
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