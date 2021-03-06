function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$VolumeLetter,

		[parameter(Mandatory = $true)]
		[System.String]
		$TargetNodeAddress
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."
    
    $FileSystem = ''
    $VolumeLabel = ''


    $Disk = Get-IscsiSession| where TargetNodeAddress -eq $TargetNodeAddress  | get-disk 
    $PartitionStyle = $Disk.PartitionStyle


    $Partitions = Get-Partition -DiskNumber $Disk.Number -ErrorAction SilentlyContinue
    Foreach($Partition in $Partitions)
    {
    If($Partition)
        {
            $VolumeLetter = $Partition.DriveLetter

            $Volume = Get-Volume -Partition $Partition -ErrorAction SilentlyContinue
            If(Volume)
            {
                $VolumeLabel = $Volume.FileSystemLabel
                $FileSystem = $Volume.FileSystem
            }
        }
    }

	
	$returnValue = @{
		VolumeLetter = $VolumeLetter
		TargetNodeAddress = $TargetNodeAddress
		VolumeLabel = $VolumeLabel
		FileSystem = $FileSystem
		PartitionStyle = $PartitionStyle
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
		$VolumeLetter,

		[parameter(Mandatory = $true)]
		[System.String]
		$TargetNodeAddress,

		[System.String]
		$VolumeLabel,

		[ValidateSet("NTFS", "FAT32", "REFS")]
		[System.String]
		$FileSystem,

		[ValidateSet("MBR", "GPT")]
		[System.String]
		$PartitionStyle
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."

	#Include this line if the resource requires a system reboot.
	#$global:DSCMachineStatus = 1

    # Check Drive
    Write-Debug "Connecting to Disk"
    $Disk = Get-IscsiSession| where TargetNodeAddress -eq $TargetNodeAddress  | get-disk
    If($Disk -eq $null)
    {
        Write-Verbose "NOK: Disk not found!!!!!!!"
        Throw 'NOK: Disk not Found!!!!!'
    }
    Else
    {
        # If drive is RAW, then partition it
        If($Disk.PartitionStyle -eq 'RAW')
        {
            Write-Debug "Found RAW Disk"

            #Bring drive online
            If($Disk.IsOffline)
            {
                #Bring Disk Online
                Write-Debug "Disk is online, bring it offline"
                Set-Disk -Number $Disk.Number -IsOffline $False
            }

            $Status = (Get-Service -Name ShellHWDetection).Status
            If($Status -eq 'Running')
            {
                Write-Debug 'OK: Stopping ShellHwDetection Service'
                Stop-Service -Name ShellHWDetection
            }

            Write-Debug "OK: Initializing, Partitioning Volume"
            $Disk | Initialize-Disk -PartitionStyle $PartitionStyle -PassThru | New-Partition -DriveLetter $VolumeLetter -UseMaximumSize |Format-Volume -FileSystem $FileSystem -NewFileSystemLabel $VolumeLabel -Confirm:$false
            Write-Verbose 'OK: Disk Initialized and Ready to use'

            If($Status -eq 'Running')
            {
                Write-Debug 'OK: Starting ShellHwDetection Service'
                Start-Service -Name ShellHWDetection
            }

        }
        Else
        {
            Write-Verbose "NOK: Disk is not in RAW Format!"
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
		$VolumeLetter,

		[parameter(Mandatory = $true)]
		[System.String]
		$TargetNodeAddress,

		[System.String]
		$VolumeLabel,

		[ValidateSet("NTFS", "FAT32", "REFS")]
		[System.String]
		$FileSystem,

		[ValidateSet("MBR" , "GPT")]
		[System.String]
		$PartitionStyle
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    # Check Drive
    $Disk = $null
    $Disk = Get-IscsiSession| where TargetNodeAddress -eq $TargetNodeAddress  | get-disk 
    If($Disk -eq $Null)
    {
        Write-Verbose "NOK: Disk on TargetNodeAddress not Found! $TargetNodeAddress"
        Throw "NOK: Disk on TargetNodeAddress not Found! $TargetNodeAddress"
        return $true
    }

    # If drive is RAW, then partition it
    $DiskPartitionStyle = $Disk.PartitionStyle

    If($Disk.PartitionStyle -eq 'RAW')
    {
        Write-Verbose "NOK: DiskPartition is RAW"
        Return $false
    }
    Else
    {
        Write-verbose "OK: DiskPartition is $DiskPartitionStyle"
        Return $true
    }
}


Export-ModuleMember -Function *-TargetResource

