function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$TargetPortalAddress,

		[parameter(Mandatory = $true)]
		[System.String]
		$NodeAddress,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$IsPersistent
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    Write-Verbose "Checking TargetPortalAddress $TargetPortalAddress"
    
    $Target = Get-IscsiTargetPortal | Where TargetPortalAddress -eq $TargetPortalAddress
    $Session = Get-IscsiSession | Where TargetNodeAddress -eq $NodeAddress
    $Disk = $Session | Get-Disk

	
	$returnValue = @{
		TargetPortalAddress = $Target.TargetPortalAddress
		NodeAddress = $Session.TargetNodeAddress
		IsPersistent = $Session.IsPersistent
		AuthenticationType = $Session.AuthenticationType
		CHAPUserName = ''
		CHAPSecret = ''
		DriveOnline = $Disk.OperationalStatus
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
		$TargetPortalAddress,

		[parameter(Mandatory = $true)]
		[System.String]
		$NodeAddress,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$IsPersistent,

		[ValidateSet("NONE","ONEWAYCHAP","MUTUALCHAP")]
		[System.String]
		$AuthenticationType,

		[System.String]
		$CHAPUserName,

		[System.String]
		$CHAPSecret,

		[System.Boolean]
		$DriveOnline
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."

	#Include this line if the resource requires a system reboot.
	#$global:DSCMachineStatus = 1

    Write-Verbose 'Changing - iSCSI service status to Automatic and starting the service'
    Set-Service -Name MSiSCSI –StartupType Automatic -Status Running

    write-Verbose "Connecting - TargetPortalAddress: $TargetPortalAddress"
    $TargetPortal = New-IscsiTargetPortal –TargetPortalAddress $TargetPortalAddress
    


    #Check if already connected



    Write-Verbose 'OK: Connecting to iSCSI LUN'
    Switch($AuthenticationType)
    {
        NONE{
            Write-Verbose 'OK: Connecting without Authentication'
            $Target = Connect-IscsiTarget -NodeAddress $NodeAddress -IsPersistent $IsPersistent
        }
        default{
            Write-Verbose 'OK: Connecting with Authentication'
            
            Try
            {
                $Target = $null
                $Target = Connect-IscsiTarget -NodeAddress $NodeAddress -IsPersistent $IsPersistent -AuthenticationType $AuthenticationType  -ChapUsername $CHAPUserName -ChapSecret $CHAPSecret  -ErrorAction SilentlyContinue
                If($Target -eq $null)
                {
                    Write-Verbose "OK: Target $NodeAddress does not exist or already connected"
                    # Bij andere fouten blijft hij proberen om de schijven aan te maken, wat niet gaat lukken
                    # Dit moet beter worden afgevangen
                }
               
            }
            Catch
            {
                #Werkt alleen als je -erroraction stop aan zet
                #Write-verbose 'oeps'
            }
        }
    }

    
 <#   
 Drive online werkt niet goed, omdat hij dan de onlinestatus gaat bepalen, moet veranderd worden in een read-only property
    If($DriveOnline)
    {
        Write-Verbose 'OK: Disk Status to Online'
        Try
        {
            Get-IscsiSession| where TargetNodeAddress -eq $NodeAddress  | Get-Disk | Set-disk -IsOffline $False -ErrorAction stop
        }
        Catch
        {
            Write-Verbose "NOK: Cannot change Disk Status!"
        }
    }
    Else
    {
        Write-Verbose 'OK: Disk Status to Offline'
        Try
        {
            Get-IscsiSession| where TargetNodeAddress -eq $NodeAddress  | Get-Disk | Set-disk -IsOffline $True -ErrorAction Stop
        }
        Catch
        {
            Write-Verbose "NOK: Cannot change Disk Status!"
        }
    }
    #>
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$TargetPortalAddress,

		[parameter(Mandatory = $true)]
		[System.String]
		$NodeAddress,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$IsPersistent,

		[ValidateSet("NONE","ONEWAYCHAP","MUTUALCHAP")]
		[System.String]
		$AuthenticationType,

		[System.String]
		$CHAPUserName,

		[System.String]
		$CHAPSecret,

		[System.Boolean]
		$DriveOnline
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."
	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."
#return $true

    $Target = Get-IscsiSession| where TargetNodeAddress -eq $NodeAddress
    If($Target.IsConnected -eq $true)
    {
        Write-Verbose 'iSCSI Target already connected'
        return $true
    }
    Else
    {
        Write-Verbose 'iSCSI Target not connected!'
        return $false
    }

}


Export-ModuleMember -Function *-TargetResource

