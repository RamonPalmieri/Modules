Configuration xSQLServerCMC

{

<#
    xSQLServer SQLServer
    {
        VDCDomainCred = $VDCDomainCred
        CloudDomainCreds = $CloudDomainCreds
    }


#>
    Param(
        
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.PSCredential]$VDCDomainCred,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.PSCredential]$CloudDomainCreds

    )
    
    Import-DSCResource -ModuleName xSQLServer
    Import-DSCResource -Module xSqlPs


        # Install SQL Server 
        WindowsFeature installdotNet45 
        {             
            Ensure = "Present" 
            Name = "AS-NET-Framework" 
        } 
      
        File SQLInstallFiles
        {
            SourcePath = "\\nsn-dc03.nsn.local\Repo\Software\SQLServer2K12\"
            DestinationPath = "c:\SQLServer2K12"
            Credential = $CloudDomainCreds
            Recurse = $true
            Type = "Directory"
        }
<#
        xSQLServerSetup installSqlServer 
        { 
            InstanceName = "SpoorWeb"  
            SourcePath = "c:\"
            SourceFolder = "SQLServer2K12"
            Features= "SQLENGINE" 
            SetupCredential = $VDCDomainCred 
            DependsOn = "[WindowsFeature]installdotNet45", "[File]SQLInstallFiles"
        } 
#>

        xSqlServerInstall SQL
        {
            InstanceName = 'Spoorweb'
            SourcePath = 'c:\SQLServer2K12'
            Features = 'SQLEngine,SSMS' 
            SqlAdministratorCredential = $VDCDomainCred
        }
    
        WindowsFeature "NET-Framework-Core"
        {
            Ensure = "Present"
            Name = "NET-Framework-Core"
        }

        WindowsFeature "NET-Framework-45-Core"
        {
            Ensure = "Present"
            Name = "NET-Framework-45-Core"
        }
}
