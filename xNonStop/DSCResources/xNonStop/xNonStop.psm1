function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $ForwarderName
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    $ConditionalForwarder = get-wmiobject -Namespace root\MicrosoftDNS -Class MicrosoftDNS_Zone -Filter "ZoneType = 4" | Where {$_.ContainerName -eq $ForwarderName}|Select -Property @{n='Name';e={$_.ContainerName}}, @{n='MasterServers';e={([string]::Join(',', $_.MasterServers))}}

    If($ConditionalForwarder -eq $null)
    {
        Write-Verbose 'Conditional Forwarder not present - Setting up Conditional Forwarder'
    }
    Else
    {
        $MasterServer = $ConditionalForwarder.MasterServers
        $Ensure = $true
    }

    
    $returnValue = @{
    ForwarderName = [System.String]
    MasterServer = [System.String]
    Ensure = [System.String]
    }

    $returnValue
 
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $ForwarderName,

        [System.String]
        $MasterServer,

        [System.String]
        $Ensure
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."
    $ConditionalForwarder = get-wmiobject -Namespace root\MicrosoftDNS -Class MicrosoftDNS_Zone -Filter "ZoneType = 4" | Where {$_.ContainerName -eq $ForwarderName}|Select -Property @{n='Name';e={$_.ContainerName}}, @{n='MasterServers';e={([string]::Join(',', $_.MasterServers))}}

    If($ConditionalForwarder -eq $null)
    {
        Try
        {
            Write-Verbose 'Conditional Forwarder not found - Installing Conditional Forwarding'
            Add-DnsServerConditionalForwarderZone -Name $ForwarderName -MasterServers $MasterServer -ReplicationScope Forest
        }
        Catch
        {
            Write-Verbose 'INSTALLING CONDTIIONAL FORWARDING FAILED!!'
            Return $false
        }
    }
    Else
    {
        Try
        {
            Write-Verbose 'Conditional Forwarder found - Configuring Master Servers'
            Set-DnsServerConditionalForwarderZone -Name $ForwarderName -MasterServers $MasterServer
        }
        Catch
        {
            Write-Verbose 'ERROR OCCURED'
        }
    }

    #Include this line if the resource requires a system reboot.
    #$global:DSCMachineStatus = 1


}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $ForwarderName,

        [System.String]
        $MasterServer,

        [System.String]
        $Ensure
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."
    $ConditionalForwarder = get-wmiobject -Namespace root\MicrosoftDNS -Class MicrosoftDNS_Zone -Filter "ZoneType = 4" | Where {$_.ContainerName -eq $ForwarderName}|Select -Property @{n='Name';e={$_.ContainerName}}, @{n='MasterServers';e={([string]::Join(',', $_.MasterServers))}}
    If($Ensure = 'Present')
    {
        If($ConditionalForwarder -eq $null)
        {
            Write-Verbose 'Conditional Forwarder not present - Setting up Conditional Forwarder'
            Return $false
        }
        Else{
            Write-Verbose 'Conditional Forwarder present - checking parameters'
            If($ConditionalForwarder.MasterServers -eq $MasterServer)
            {
                Write-Verbose 'MasterServers configured correctly - Nothing to do'
                Return $true
            }
            Else
            {
                Write-Verbose 'MasterServers configured incorrectly - Setting MasterServers'
                Return $false
            }
        }
    }
    Else
    {
        If($ConditionalForwarder -eq $null)
        {
            Write-Verbose 'Conditional Forwarder not present - Nothing to do'
            Return $true
        }
        Else
        {
            Write-Verbose 'Conditional Forwarder Present - Remove Conditional Forwarder'
            Write-Verbose 'Ooit deze settings nalopen om te kijken of we ook daadwerkelijk moeten verwijderen!'
        }
    }

    <#
    $result = [System.Boolean]
    
    $result
    #>
}


Export-ModuleMember -Function *-TargetResource

