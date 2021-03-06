function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$NodeAddress
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."


	<#
	$returnValue = @{
		NodeAddress = [System.String]
		DriveLetter = [System.Boolean]
		FileSystem = [System.String]
		Label = [System.String]
	}

	$returnValue
	#>
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$NodeAddress,

		[System.Boolean]
		$DriveLetter,

		[ValidateSet("NTFS","ReFS","exFAT","FAT","FAT32")]
		[System.String]
		$FileSystem,

		[System.String]
		$Label
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."

	#Include this line if the resource requires a system reboot.
	#$global:DSCMachineStatus = 1

    Write-Verbose 'Connect iSCSI Session to Disk'
    $Drive = Get-IscsiSession| where TargetNodeAddress -eq $NodeAddress  | get-disk

    if($Drive.PartitionStyle -eq 'RAW')
    {
        Write-Verbose 'Initializing disk'
        Initialize-Disk -Number $Drive.Number -PartitionStyle 'MBR' -PassThru

        $Service = Get-Service -Name ShellHWDetection
        If($Service.Status -eq 'Running')
        {
            Write-Verbose 'Stopping Shell Hardware Detection Service'
            $RestartService = $true
            Set-Service -Name ShellHWDetection -Status Stopped
        }
        Else
        {
            $RestartService = $False
        }
        Write-Verbose 'Creating and Formating Partion'
        New-Partition -DriveLetter $DriveLetter -UseMaximumSize |Format-Volume -FileSystem $FileSystem -NewFileSystemLabel $Label -Confirm:$false

        #If needed, start service again
        if($RestartService)
        {
            Write-Verbose 'Starting Shell Hardware Detection Service'
            Set-Service -Name ShellHWDetection -Status Running   
        }
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
		$NodeAddress,

		[System.Boolean]
		$DriveLetter,

		[ValidateSet("NTFS","ReFS","exFAT","FAT","FAT32")]
		[System.String]
		$FileSystem,

		[System.String]
		$Label
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    
}


Export-ModuleMember -Function *-TargetResource

