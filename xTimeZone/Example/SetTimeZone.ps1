﻿#--------------------------------------------------------------------------------- 

Configuration SetTimeZone
{
   Param
   (
       [String[]]$NodeName = $env:COMPUTERNAME,

       [Parameter(Mandatory = $true)]
       [ValidateNotNullorEmpty()]
       [String]$SystemTimeZone
   )

   Import-DSCResource -ModuleName xTimeZone

   Node $NodeName
   {
        xTimeZone TimeZoneExample
        {
            TimeZone = $SystemTimeZone
        }
   }
}

SetTimeZone -NodeName "CON-SRV02" -SystemTimeZone "Tonga Standard Time"
Start-DscConfiguration -Path .\SetTimeZone -Wait -Verbose -Force