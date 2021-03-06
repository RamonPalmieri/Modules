function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$DiskWitness
	)


	$returnValue = @{
		DiskWitness = (Get-ClusterQuorum).QuorumResource.name
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
		$DiskWitness
	)

	Write-Debug "OK: Adding Diskwitness quorum $Diskwitness"
    Set-ClusterQuorum -DiskWitness $DiskWitness

}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$DiskWitness
	)

	$QuorumResource = Get-ClusterQuorum -ErrorAction SilentlyContinue
    If($QuorumResource.QuorumResource -eq $DiskWitness)
    {
        Write-Debug "OK: DiskWitness $DiskWitness exist"
        return $true
    }
    Else
    {
        Write-Verbose "NOK: DiskWitness $Diskwitness does not exist"
        Return $false
    }
}

Export-ModuleMember -Function *-TargetResource

