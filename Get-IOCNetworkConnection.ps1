<#
.Synopsis
    Searches multiple remote computers for connections against provided IPs and/or Ports.

.Description
    The cmdlet all allows you to query multiple remote computers to search if any of them have a current TCP Connection to one or more specific remote IP addresses or ports. Useful to query if endpoints are connected to specific IPs that are known to be malicious or known are using malicious ports. For example, if you query for port 4444, you will see all computers that have a connection with that port.

    Version        : v1.0
    Author         : high101bro
    Email          : high101bro@gmail.com
    Website        : https://github.com/high101bro

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
    The following command queries a list of computers for two remote IP addresses.

    .\Get-IOCNetworkConnection.ps1 -ComputerName (Get-Content .\MyComputerList.txt) -IP '192.168.138.170','52.33.41.59'

.Example
    The following command queries multiple computers for multiple remote IPs and multiple remote ports.

    .\Get-IOCNetworkConnection.ps1 -ComputerName Computer1,Computer2,Computer3 -IP '192.168.138.170','52.33.41.59' -Port (Get-Content .\PortsList.txt)

#>
param(
    [string[]]$ComputerName = 'localhost',
    [string[]]$IP = "127.0.0.1",
    [string[]]$Port
)
Foreach ($Computer in $ComputerName) {
    Invoke-Command -ComputerName $Computer -ScriptBlock {
        param (
            $IP,
            $Port,
            $Computer
        )
        $Connections = Get-NetTCPConnection
        $Processes   = Get-WmiObject -Class Win32_Process
        $ConnectionsFound = @()        

        foreach ($Conn in $Connections) { 
            if (($Conn.RemoteAddress -in $IP) -or ($Conn.RemotePort -in $Port)) { 
                $Count++
                
                foreach ($Proc in $Processes) {
                    if ($Conn.OwningProcess -eq $Proc.ProcessId) {
                        $Conn | Add-Member -MemberType NoteProperty -Name 'Duration' -Value $((New-TimeSpan -Start ($Conn.CreationTime)).ToString())
                        $Conn | Add-Member -MemberType NoteProperty -Name 'ParentPID' -Value $Proc.ParentProcessId
                        $Conn | Add-Member -MemberType NoteProperty -Name 'ProcessName' -Value $Proc.Name
                        $Conn | Add-Member -MemberType NoteProperty -Name 'CommandLine' -Value $Proc.CommandLine
                    }
                }
                $ConnectionsFound += [PSCustomObject]@{
                    PSComputerName  = $Computer
                    LocalAddress    = $conn.LocalAddress
                    LocalPort       = $conn.LocalPort
                    RemoteAddress   = $conn.RemoteAddress
                    RemotePort      = $conn.RemotePort
                    State           = $conn.State
                    Duration        = $((New-TimeSpan -Start ($Conn.CreationTime)).ToString())
                    ParentPID       = $conn.ParentPID
                    ProcessID       = $conn.OwningProcess
                    ProcessName     = $conn.ProcessName
                    CommandLine     = $Proc.CommandLine
                }
            }
        }
        return $ConnectionsFound
    } -ArgumentList @($IP,$Port,$Computer)
}
