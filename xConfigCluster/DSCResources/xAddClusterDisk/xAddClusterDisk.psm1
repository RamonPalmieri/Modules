function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
        [parameter(Mandatory = $true)]
		[System.String]
		$TargetNodeAddress,

		[parameter(Mandatory = $true)]
		[System.String]
		$Label
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."

<#    
    $ClusterResource = Get-ClusterResource -Name $Label
    $State = $ClusterResource.State
    $OwnerGroup = $ClusterResource.OwnerGroup
#>

    $returnValue = @{
        TargetNodeAddress = $TargetNodeAddress
        Label = $Label
	}

	return $returnValue	
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$TargetNodeAddress,

		[parameter(Mandatory = $true)]
		[System.String]
		$Label
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."

	#Include this line if the resource requires a system reboot.
	#$global:DSCMachineStatus = 1

    # set
    Write-Debug "OK: Setting Cluster Disk $Label"
    Write-Debug "OK: Check if disk is already added to cluster with wrong name"
  
    $ClusterDisks =  Get-CimInstance -ClassName MSCluster_Resource -Namespace root/mscluster -Filter "type = 'Physical Disk'" 
    foreach ($ClusterDisk in $ClusterDisks)
    {
        $DiskResource = Get-CimAssociatedInstance -InputObject $ClusterDisk -ResultClass MSCluster_DiskPartition

        $Name = $ClusterDisk.Name
        If($DiskResource.VolumeLabel -eq $Label -and $ClusterDisk.Name -ne $Label)
        {
            Write-Verbose "OK: Disk already mountend, but wrong label $Name"
            (Get-ClusterResource -Name $ClusterDisk.name).Name = $Label
            Return
        }
     }

   
     #Cluster Resource does not exist, so create it

    $Disk = Get-IscsiSession| where TargetNodeAddress -eq $TargetNodeAddress  | get-disk -ErrorAction Ignore
    If($Disk -eq $null -Or $Disk -eq '')
    {
        Write-Verbose "NOK: Disk is not found!"
        Throw "NOK: Disk is not found!"
        return
    }

    $DiskStatus = $disk.OperationalStatus
    $DiskNumber = $Disk.Number

    If($Disk.OperationalStatus -eq 'Online')
    {
        Write-Debug "OK: Disk $DiskNumber is online, take offline"
        $Disk = Set-Disk -Number $DiskNumber -IsOffline $true
    }
    Else
    {
        Write-Debug "OK: Disk $DiskNumber is offline"
    }
 
    #Disk is nu offline

    Write-Debug "OK: Add Disk $DiskNumber to Cluster Disk $Label"

    $ClusterDisk = $Disk | Add-ClusterDisk -ErrorAction Ignore
    (Get-ClusterResource -Name $ClusterDisk.name).Name = $Label

    $ClusterResouce = Get-ClusterResource -Name $ClusterDisk.name
    

    If($ClusterResouce -eq $null -or $ClusterResource -eq '')
    {
        Write-Verbose "NOK: Cluster Disk $Label does not exist"
        Throw "NOK: Cluster Disk $Label does not exist"
        Return
    }
        
    
    
        
    Write-Verbose "OK: Cluster Disk $Label exists"
    Write-Verbose "OK: Start Cluster Resource $Label"
    Start-ClusterResource -Name $Label

}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$TargetNodeAddress,

		[parameter(Mandatory = $true)]
		[System.String]
		$Label
	)

    Write-Debug "TargetNodeAddress: $TargetNodeAddress"
    Write-Debug "Label: $Label"


    #Check of Clusterdisk aanwezig is op basis van label
    $Resource = $null
    $Resource = Get-ClusterResource -Name $Label -ErrorAction ignore
    If($Resource -eq $null)
    {
        Write-Verbose "NOK: Cluster Resource $Label does not exist"
        Return $false
    }
    Else
    {
        Write-Verbose "OK: Cluster Resource $Label does exist"
        return $true
    }
}


Export-ModuleMember -Function *-TargetResource

