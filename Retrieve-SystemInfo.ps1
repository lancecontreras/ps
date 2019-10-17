[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [String]$Comment
)
$systeminfo = systeminfo
function Get-SystemInfoValue{  
    param([int]$index)
    $spl = $systeminfo[$index] -split ":"
    $val = $spl[1].Replace(",","").Trim()
    return $val
}

# Get Hostname 
$hostname = Get-SystemInfoValue(1)

# Get OS Version 
$os_version = Get-SystemInfoValue(3)

# Manufacturer
$manu = Get-SystemInfoValue(12)

# Model 
$model = Get-SystemInfoValue(13)

#OS Name

#Get Serial number 
$sn = Get-WmiObject Win32_bios | Select-Object serialnumber
$ports = Get-WmiObject Win32_PnPSignedDriver | Where-Object DeviceClass -eq 'PORTS' | Select-Object FriendlyName 
$postparam = @{SerialNumber=$sn.serialnumber; OSVersion=$os_version; Hostname = $hostname;Manufacturer=$manu;Model=$model;Comments=$Comment}

Invoke-WebRequest -Method POST -Body ($postparam | ConvertTo-Json) -ContentType "application/json" -Uri http://contreras.eastus.cloudapp.azure.com/raven/