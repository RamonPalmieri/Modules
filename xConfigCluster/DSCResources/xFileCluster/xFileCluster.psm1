function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$Storage,

		[parameter(Mandatory = $true)]
		[System.String]
		$IPAddress
	)

    $ClusterResource = Get-ClusterResource -Name $Name
    $ResourceIP = Get-ClusterResource | where {$_.ownergroup -eq $Name  -and $_.ResourceType -eq 'IP Address'}| Get-ClusterParameter -name address
    $ResourceStorage = Get-ClusterResource | where {$_.ownergroup -eq $Name  -and $_.ResourceType -eq 'Physical Disk'} 

	$returnValue = @{
		Name = $ClusterResource.Name
		Storage = $ResourceStorage.Name
		IPAddress = $ResourceIP.Value
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
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$Storage,

		[parameter(Mandatory = $true)]
		[System.String]
		$IPAddress
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."

	#Include this line if the resource requires a system reboot.
	#$global:DSCMachineStatus = 1


    $FileCluster = $null
    $FileCluster = Get-ClusterResource | where Name -eq $Name -ErrorAction SilentlyContinue
    If($FileCluster -eq $null)
    {
        # Filecluster does not exist, create
        $FileCluster = Add-ClusterFileServerRole -Name $Name -Storage $Storage -StaticAddress $IPAddress -ErrorAction stop
        If($FileCluster -eq $null)
        {
            Write-Verbose "NOK: Could not create Filecluster $Name"
            Write-Debug "NOK: Could not create Filecluster $Name, IP $IPAddress, Storage $Storage"
            Throw "NOK: Could not create FileCluster $Name"
            return
        }
        Else
        {
            Write-verbose "OK: Setting Node $env:computername as OwnerNode"
            Set-ClusterOwnerNode -Resource $Name -Owners $env:computername
        }
    }
    Else
    {
         Write-Verbose "OK: Set Cluster Owner for FileCluster $Name"
         Set-ClusterOwnerNode -Resource $Name -Owners $ClusterObject.OwnerNodes.Name
    }

    
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$Storage,

		[parameter(Mandatory = $true)]
		[System.String]
		$IPAddress
	)

    $FileCluster = $null
    $FileCluster = Get-ClusterResource | where Name -eq $Name -ErrorAction SilentlyContinue
    If($FileCluster -eq $null)
    {
        Write-Verbose "NOK: Filecluster $Name does not exist"
        Return $false
    }
	else
    {
        Write-Debug "OK: FileCluster $Name does exist"
        $ClusterObject = Get-ClusterOwnerNode -Resource $Name
        If($ClusterObject.OwnerNodes.Name.Contains($env:COMPUTERNAME))
        {
            Write-Debug "OK: Node $env:COMPUTERNAME is (posible) owner of $Name"
            Return $true
        }
        Else
        {
            Write-Verbose "NOK: Node $env:COMPUTERNAME is not an owner of $Name"
            Return $false
        }
        
    }
}


Export-ModuleMember -Function *-TargetResource

