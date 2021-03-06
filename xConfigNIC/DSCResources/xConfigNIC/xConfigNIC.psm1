function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$MACAddress,

		[parameter(Mandatory = $true)]
		[ValidateSet("DHCP","Static")]
		[System.String]
		$Mode
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    $Adapter = Get-NetAdapter | where MacAddress -eq $MACAddress 
    $AdapterMode = Get-NetIPInterface -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4
    $AdapterIP = Get-NetIPAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4
    $AdapterNet = Get-NetIPConfiguration -InterfaceIndex $Adapter.ifIndex
    $AdapterDNS = Get-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4

    #Volgens mij gaat DNS niet goed, omdat daar geen komma in zit
    #DNS = $AdapterDNS.ServerAddresses
    #$AdapterNet.IPv4DefaultGateway

	$returnValue = @{
		MACAddress = $MACAddress
		Mode = $Mode
		IPAddress = $AdapterIP.IPAddress
		Netmask = $AdapterIP.PrefixLength
		Gateway = $AdapterNet.IPv4DefaultGateway.Nexthop
		DNS = '192.168.30.151'
		Alias = $Adapter.Name
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
		$MACAddress,

		[parameter(Mandatory = $true)]
		[ValidateSet("DHCP","Static")]
		[System.String]
		$Mode,

		[System.String]
		$IPAddress,

		[System.String]
		$Netmask,

		[System.String]
		$Gateway,

		[System.String]
		$DNS,

		[System.String]
		$Alias
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."

	#Include this line if the resource requires a system reboot.
	#$global:DSCMachineStatus = 1

    # Retrieve the network adapter that you want to configure
    $Adapter = Get-NetAdapter | where MacAddress -eq $MACAddress


    #Set Alias
    If($Alias -ne '')
    {
        Write-verbose 'Renaming NIC'
        $Adapter | Rename-NetAdapter -NewName $Alias
        #Refresh properties, so $Adapter has right alias
        $Adapter = Get-NetAdapter | where MacAddress -eq $MACAddress 
    }

    #Set NIC to Static
    Switch($Mode)
    {
        DHCP
        {
            Write-Verbose 'Setting NIC to DHCP'
            Set-NetIPInterface -InterfaceIndex $Adapter.ifIndex –Dhcp Enabled
        }

        Static
        {
            Write-Verbose 'Setting NIC to Static'
            Set-NetIPInterface -InterfaceIndex $Adapter.ifIndex –Dhcp Disabled

            
            # Remove any existing IP, gateway from our ipv4 adapter
            If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress)
            {
                Try{
                    Write-Verbose 'Remove IP Addresses From NIC'
                    $adapter | Remove-NetIPAddress -AddressFamily IPv4 -Confirm:$false
                }
                Catch{}
            }
           
             # Remove any Gateway's
             If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway -and $Gateway -ne '')
             {
                Try{
                    Write-Verbose 'Remove Gateway From NIC'
                    $adapter | Remove-NetRoute -AddressFamily IPv4 -Confirm:$false
                }
                Catch {}
             }
            
            # NIC is cleared
            # Set IP address, SubnetMask & Gateway
            If($Gateway -ne '')
            {
                Write-Verbose 'Setting IP, SubnetMask and Gateway'
                $Dummy = New-NetIPAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4 -IPAddress $IPAddress -PrefixLength $Netmask -DefaultGateway $Gateway
            }
            Else
            {
                Write-Verbose 'Setting IP and SubnetMask'
                $Dummy = New-NetIPAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4 -IPAddress $IPAddress -PrefixLength $Netmask
            }

            if($DNS -ne '')
            {
                Write-Verbose 'Setting DNS On NIC'
                Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses $DNS
            }
            else
            {
                #Write-Verbose 'Clearing DNS On NIC'
                #Set-DnsClientServerAddress –InterfaceIndex $Adapter.ifIndex -ResetServerAddresses
            }
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
		$MACAddress,

		[parameter(Mandatory = $true)]
		[ValidateSet("DHCP","Static")]
		[System.String]
		$Mode,

		[System.String]
		$IPAddress,

		[System.String]
		$Netmask,

		[System.String]
		$Gateway,

		[System.String]
		$DNS,

		[System.String]
		$Alias
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."


	# Retrieve the network adapter that you want to configure
    $Adapter = Get-NetAdapter | where MacAddress -eq $MACAddress 
    $AdapterMode = Get-NetIPInterface -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4
    $AdapterIP = Get-NetIPAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4
    $AdapterNet = Get-NetIPConfiguration -InterfaceIndex $Adapter.ifIndex
    $AdapterDNS = Get-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4

    $TestResult = $true

    If($Alias -ne '')
    {
        if($Adapter.Name -ne $Alias)
        {
            $TestResult = $false
            Write-Verbose 'Alias incorrect!'
        }
    }

    Switch($Mode)
     {
        DHCP
        {
            $AdapterMode.Dhcp
            If($AdapterMode.Dhcp -eq 'Disabled')
            {
                Write-Verbose 'NIC is not DHCP!'
                $TestResult = $false
            }
            #klaar met checks, return
            return $TestResult
        }

        Static
        {
            #NIC is static, nu verder checken
            #IPAddress?
            If($IPAddress -ne '')
            {
                If($AdapterIP.IPAddress -ne $IPAddress)
                {
                    $TestResult = $false
                    Write-Verbose 'IP Address incorrect!'
                }
            }

            #Netmask?
            If($Netmask -ne '')
            {
                If($AdapterIP.PrefixLength -ne $Netmask)
                {
                    $TestResult = $false
                    Write-Verbose 'Netmask incorrect!'
                }
            }

            #Gateway?
            If($Gateway -ne '')
            {
                If($AdapterNet.IPv4DefaultGateway.NextHop -ne $Gateway)
                {
                    $TestResult = $false
                    Write-Verbose 'Gateway incorrect!'
                }
            }
     
            #DNS
            if($DNS -ne '')
            {
                $DNSModified = $DNS -replace ',', ' '
                If($DNSModified -ne $AdapterDNS.ServerAddresses)
                {
                    $TestResult = $false
                    Write-Verbose 'DNS incorrect!'
                }
            }
        }
    }
    If($TestResult)
    {
        Write-Verbose 'NIC Settings Correct'
    }
    return $TestResult
}


Export-ModuleMember -Function *-TargetResource

