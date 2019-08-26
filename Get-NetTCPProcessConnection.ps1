<#

    Version        : v1.0
    Author         : high101bro
    Email          : high101bro@gmail.com
    Website        : https://github.com/high101bro

"What is the Difference Between 127.0.0.1 and 0.0.0.0?
    127.0.0.1 is the loopback address (also known as localhost).
    0.0.0.0 is a non-routable meta-address used to designate an invalid, unknown, or non-applicable target (a ‘no particular address’ place holder).
    :: is an unspecified address, 0:0:0:0:0:0:0:0 (“::” in compressed form) is used to indicate an unknown address.
"
#>
param(
    [Switch]$IncludeLocalConnections
)
if ($IncludeLocalConnections) {
    $Connections = Get-NetTCPConnection
}
else {
    $Connections = Get-NetTCPConnection `
    | Where-Object  {($_.RemoteAddress -ne '0.0.0.0') `
                -and ($_.RemoteAddress -ne '127.0.0.1') `
                -and ($_.RemoteAddress -ne '::') `
                -and ($_.RemoteAddress -ne '::1')}
}

$Processes   = Get-WmiObject -Class Win32_Process

ForEach ($Conn in $Connections) {
    foreach ($Proc in $Processes) {
        if ($Conn.OwningProcess -eq $Proc.ProcessId) {
            $Conn | Add-Member -MemberType NoteProperty -Name 'ProcessName' -Value $Proc.Name
            $Conn | Add-Member -MemberType NoteProperty -Name 'Duration' -Value $((New-TimeSpan -Start ($Conn.CreationTime)).ToString())
            $Conn | Add-Member -MemberType NoteProperty -Name 'CommandLine' -Value $Proc.CommandLine
        }
    }        
}

return $Connections `
    | Select-Object -Property PScomputername, RemoteAddress, RemotePort, OwningProcess, ProcessName, CreationTime, CommandLine `
    | Sort-Object -Property ProcessName `
    | Format-Table -AutoSize
