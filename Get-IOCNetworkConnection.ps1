<#
.Synopsis
    Searches multiple remote computers for connections against provided IPs and/or Ports.

    File Name      : Get-IOCNetworConnection.ps1
    Version        : v1.0
    Author         : high101bro
    Email          : high101bro@gmail.com
    Website        : https://github.com/high101bro

.Description
    The cmdlet all allows you to query multiple remote computer to seach if any of them have a current TCP Connection
    to one or mote specific remote IP addresses or ports. Useful to query if endpoints are connected to specific IPs 
    that are known to be malicious or known are using malicious ports. For example if you query for port 4444, you will
    see all computers that have a connection with that port.

.Parameter ComputerName
    Enter one or more ComputerNames to query for connections.

.Parameter IP
    Enter one or more remote IP addresses to query for in remote computer(s) network connections.

.Parameter Port
    Enter one or more remote port numbers to query for in remote computer(s) network connections.

.Example
    The following command queries two computers for connections with various ports.

    .\Get-IOCNetworkConnection.ps1 -ComputerName Computer1,Computer2 -Port 4444,80,8009

.Example
    The following command queries a list of computers for two remote ip addresses.

    .\Get-IOCNetworkConnection.ps1 -ComputerName (Get-Content .\MyComputerList.txt) -IP '192.168.138.170','52.33.41.59'

.Example
    The following command queries multiple computers for multiple remote IPs and multiple remote ports.

    .\Get-IOCNetworkConnection.ps1 -ComputerName Computer1,Computer2,Computer3 -IP '192.168.138.170','52.33.41.59' -Port (Get-Content .\PortsList.txt)

.Inputs
    None

.Outputs
    [PSCustomObject]

.Link
    https://github.com/high101bro
#>
[CmdletBinding(DefaultParameterSetName = 'Set 1')]
param(
    [Parameter(
        Position = 0, 
        Mandatory = $false,
        ParameterSetName = 'Set 1'
        )]
    [Parameter(
        Position = 0, 
        Mandatory = $false,
        ParameterSetName = 'Set 2'
        )]
            [string[]]$ComputerName = 'localhost',
    [Parameter(
        Position = 1, 
        Mandatory = $false,
        ParameterSetName = 'Set 1'
        )]
    [Parameter(
        Position = 1, 
        Mandatory = $False,
        ParameterSetName = 'Set 2'
        )]
            [string[]]$IP,
    [Parameter(
        Position = 1, 
        Mandatory = $false,
        ParameterSetName = 'Set 1'
        )]
    [Parameter(
        Position = 2, 
        Mandatory = $false,
        ParameterSetName = 'Set 2'
        )]
            [string[]]$Port
)
Foreach ($Computer in $ComputerName) {
    Invoke-Command -ComputerName $Computer -ScriptBlock {
        param ($IP,$Port,$Computer)
        $Connections = Get-NetTCPConnection
        #$match = [Ordered]@{}
        #$Count = 1
        foreach ($Conn in $Connections) { 
            if (($Conn.RemoteAddress -in $IP) -or ($Conn.RemotePort -in $Port)) { 
                Write-Host "$Computer $($conn.RemoteAddress):$($conn.RemotePort)" -ForegroundColor Cyan
                #"{0,-20} {1,-20}:{2,-20}" -f $Computer,$conn.RemoteAddress,$conn.RemotePort
                #$match += @{ $("Connection $Count") = "$($Conn.RemoteAddress):$($Conn.RemotePort)" }
                #$Count++
            }
        }
        #return [PSCustomObject]$match
    } -ArgumentList @($IP,$Port,$Computer)
}