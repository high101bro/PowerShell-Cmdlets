$ErrorActionPreference = 'SilentlyContinue'

$Processes   = Get-WmiObject -Class Win32_Process

$ParameterSets = (Get-Command Get-NetTCPConnection).ParameterSets | Select -ExpandProperty Parameters
if (($ParameterSets | Foreach {$_.name}) -contains 'OwningProcess') {
    $NetworkConnections = Get-NetTCPConnection
}
else {
    $NetworkConnections = netstat -nao -p TCP
    $NetStat = Foreach ($line in $NetworkConnections[4..$NetworkConnections.count]) {
        $line = $line -replace '^\s+',''
        $line = $line -split '\s+'
        $properties = @{
            Protocol      = $line[0]
            LocalAddress  = ($line[1] -split ":")[0]
            LocalPort     = ($line[1] -split ":")[1]
            RemoteAddress = ($line[2] -split ":")[0]
            RemotePort    = ($line[2] -split ":")[1]
            State         = $line[3]
            ProcessId     = $line[4]
        }
        $Connection = New-Object -TypeName PSObject -Property $properties
        $proc       = Get-WmiObject -query ('select * from win32_process where ProcessId="{0}"' -f $line[4])
        $Connection | Add-Member -MemberType NoteProperty OwningProcess $proc.ProcessId
        $Connection | Add-Member -MemberType NoteProperty ParentProcessId $proc.ParentProcessId
        $Connection | Add-Member -MemberType NoteProperty Name $proc.Caption
        $Connection | Add-Member -MemberType NoteProperty ExecutablePath $proc.ExecutablePath
        $Connection | Add-Member -MemberType NoteProperty CommandLine $proc.CommandLine
        $Connection | Add-Member -MemberType NoteProperty PSComputerName $env:COMPUTERNAME
        if ($Connection.ExecutablePath -ne $null -AND -NOT $NoHash) {
            $MD5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
            $hash = [System.BitConverter]::ToString($MD5.ComputeHash([System.IO.File]::ReadAllBytes($proc.ExecutablePath)))
            $Connection | Add-Member -MemberType NoteProperty MD5 $($hash -replace "-","")
        }
        else {
            $Connection | Add-Member -MemberType NoteProperty MD5 $null
        }
        $Connection
    }
    $NetworkConnections = $NetStat | Select-Object -Property PSComputerName,Protocol,LocalAddress,LocalPort,RemoteAddress,RemotePort,State,Name,OwningProcess,ProcessId,ParentProcessId,MD5,ExecutablePath,CommandLine
}

ForEach ($Conn in $NetworkConnections) {
    foreach ($Proc in $Processes) {
        if ($Conn.OwningProcess -eq $Proc.ProcessId) {
            $Conn | Add-Member -MemberType NoteProperty -Name 'ProcessName' -Value $Proc.Name
            $Conn | Add-Member -MemberType NoteProperty -Name 'Duration' -Value $((New-TimeSpan -Start ($Conn.CreationTime)).ToString())
            $Conn | Add-Member -MemberType NoteProperty -Name 'CommandLine' -Value $Proc.CommandLine
        }
    }        
}
$NetworkConnections `
    | Select-Object -Property @{name="PSComputerName";expression={$env:COMPUTERNAME}}, RemoteAddress, RemotePort, OwningProcess, ProcessName, CreationTime, CommandLine `
    | Sort-Object -Property ProcessName
