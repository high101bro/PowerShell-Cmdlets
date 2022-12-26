﻿function Get-EndpointData {
param(
    [string]$ComputerName = 'localhost',
    [hashtable]$CompiledResults = [ordered]@{}
)

#########################
### Overview
#########################

    #####################
    #####################
    $CompiledResults.add('GetComputerInfo',$(
        Get-ComputerInfo
    ))
        #$Win32_OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem #<-- Similar to above

    #####################
    #####################
    $CompiledResults.add('GetSystemDateTimes',$(
        $os = $null
        $GetTimeZone = $null
        $os = Get-WmiObject win32_operatingsystem
        $GetTimeZone = Get-Timezone
        if ($GetTimeZone) {
            $DateTimes = [PSCustomObject]@{
                LastBootUpTime             = $os.ConvertToDateTime($os.LastBootUpTime)
                InstallDate                = $os.ConvertToDateTime($os.InstallDate)
                LocalDateTime              = $os.ConvertToDateTime($os.LocalDateTime)
                TimeZone                   = $GetTimeZone.StandardName
                BaseUtcOffset              = $GetTimeZone.BaseUtcOffset
                SupportsDaylightSavingTime = $GetTimeZone.SupportsDaylightSavingTime
            }
            $DateTimes | Select-Object @{n='ComputerName';E={$env:COMPUTERNAME}}, LocalDateTime, LastBootUpTime, InstallDate, TimeZone, BaseUtcOffset, SupportsDaylightSavingTime
        }
        else {
            $DateTimes = [PSCustomObject]@{
                LastBootUpTime  = $os.ConvertToDateTime($os.LastBootUpTime)
                InstallDate     = $os.ConvertToDateTime($os.InstallDate)
                LocalDateTime   = $os.ConvertToDateTime($os.LocalDateTime)
                CurrentTimeZone = $os.CurrentTimeZone
            }
            $DateTimes | Select-Object @{n='ComputerName';E={$env:COMPUTERNAME}}, LocalDateTime, LastBootUpTime, InstallDate, CurrentTimeZone
        }    
    ))

    #####################
    #####################
    $CompiledResults.add('GetComputerRestorePoint',$(
        Get-ComputerRestorePoint | Select-Object -Property *
    ))

    #####################
    #####################
    $CompiledResults.add('GetChildItemEnv',$(
        Get-ChildItem Env:
    ))
        # Get-WmiObject -Class Win32_Environment # <-- similar as above

    #####################
    #####################
    $CompiledResults.add('GetChildItemVariable',$(
        Get-ChildItem Variable:
    ))

    #####################
    #####################
    $CompiledResults.add('GetChildItemFunction',$(
        Get-ChildItem Function:
    ))

    #####################
    #####################
    $CompiledResults.add('GetPSDrive',$(
        Get-PSDrive
    ))
    
    #####################
    #####################
    $CompiledResults.add('GetScheduledTask',$(
        Get-ScheduledTask | Select-Object -Property *
    ))
    
    #####################
    #####################
    $CompiledResults.add('schtasks',$(
        schtasks /query /V /FO CSV | ConvertFrom-Csv
    ))

    #####################
    #####################
    $CompiledResults.add('GetWindowsOptionalFeature',$(
        Get-WindowsOptionalFeature -Online | Select-Object -Property *
    ))

#########################
### Networking
#########################

    #####################
    #####################
    $CompiledResults.add('GetNetworkConnectionsTCPEnriched',$(
        if ([bool]((Get-Command Get-NetTCPConnection).ParameterSets | Select-Object -ExpandProperty Parameters | Where-Object Name -match OwningProcess)) {
            $Processes           = Get-WmiObject -Class Win32_Process
            $Connections         = Get-NetTCPConnection

            foreach ($Conn in $Connections) {
                foreach ($Proc in $Processes) {
                    if ($Conn.OwningProcess -eq $Proc.ProcessId) {
                        $Conn | Add-Member -MemberType NoteProperty 'PSComputerName'  $env:COMPUTERNAME -Force
                        $Conn | Add-Member -MemberType NoteProperty 'Protocol'        'TCP'
                        $Conn | Add-Member -MemberType NoteProperty 'Duration'        ((New-TimeSpan -Start ($Conn.CreationTime)).ToString())
                        $Conn | Add-Member -MemberType NoteProperty 'ProcessId'       $Proc.ProcessId
                        $Conn | Add-Member -MemberType NoteProperty 'ParentProcessId' $Proc.ParentProcessId
                        $Conn | Add-Member -MemberType NoteProperty 'ProcessName'     $Proc.Name
                        $Conn | Add-Member -MemberType NoteProperty 'CommandLine'     $Proc.CommandLine
                        $Conn | Add-Member -MemberType NoteProperty 'ExecutablePath'  $proc.ExecutablePath
                        $Conn | Add-Member -MemberType NoteProperty 'ScriptNote'      'Get-NetTCPConnection Enhanced'

                        if ($Conn.ExecutablePath -ne $null) {
                            $MD5Hash = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
                            $Hash    = [System.BitConverter]::ToString($MD5Hash.ComputeHash([System.IO.File]::ReadAllBytes($proc.ExecutablePath)))
                            $Conn | Add-Member -MemberType NoteProperty MD5Hash $($Hash -replace "-","")
                        }
                        else {
                            $Conn | Add-Member -MemberType NoteProperty MD5Hash $null
                        }
                    }
                }
            }
        }
        else {
            function Get-Netstat {
                $NetworkConnections = netstat -nao -p TCP
                $NetStat = Foreach ($line in $NetworkConnections[4..$NetworkConnections.count]) {
                    $line = $line -replace '^\s+',''
                    $line = $line -split '\s+'
                    $Properties = @{
                        Protocol      = $line[0]
                        LocalAddress  = ($line[1] -split ":")[0]
                        LocalPort     = ($line[1] -split ":")[1]
                        RemoteAddress = ($line[2] -split ":")[0]
                        RemotePort    = ($line[2] -split ":")[1]
                        State         = $line[3]
                        ProcessId     = $line[4]
                        OwningProcess = $line[4]
                    }
                    $Connection = New-Object -TypeName PSObject -Property $Properties
                    $proc       = Get-WmiObject -query ('select * from win32_process where ProcessId="{0}"' -f $line[4])
                    $Connection | Add-Member -MemberType NoteProperty 'PSComputerName'  $env:COMPUTERNAME -Force
                    $Connection | Add-Member -MemberType NoteProperty 'ParentProcessId' $proc.ParentProcessId
                    $Connection | Add-Member -MemberType NoteProperty 'ProcessName'     $proc.Caption
                    $Connection | Add-Member -MemberType NoteProperty 'ExecutablePath'  $proc.ExecutablePath
                    $Connection | Add-Member -MemberType NoteProperty 'CommandLine'     $proc.CommandLine
                    $Connection | Add-Member -MemberType NoteProperty 'CreationTime'    ([WMI] '').ConvertToDateTime($proc.CreationDate)
                    $Connection | Add-Member -MemberType NoteProperty 'Duration'        ((New-TimeSpan -Start ([WMI] '').ConvertToDateTime($proc.CreationDate)).ToString())
                    $Connection | Add-Member -MemberType NoteProperty 'ScriptNote'      'NetStat.exe Enhanced'

                    if ($Connection.ExecutablePath -ne $null) {
                        $MD5Hash = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
                        $Hash    = [System.BitConverter]::ToString($MD5Hash.ComputeHash([System.IO.File]::ReadAllBytes($proc.ExecutablePath)))
                        $Connection | Add-Member -MemberType NoteProperty MD5Hash $($Hash -replace "-","")
                    }
                    else {
                        $Connection | Add-Member -MemberType NoteProperty MD5Hash $null
                    }
                    $Connection
                }
                $NetStat
            }
            $Connections = Get-Netstat
        }
        $Connections | Select-Object -Property PSComputerName, Protocol,LocalAddress,LocalPort,RemoteAddress,RemotePort,State,ProcessName,ProcessId,ParentProcessId,CreationTime,Duration,CommandLine,ExecutablePath,MD5Hash,OwningProcess,ScriptNote -ErrorAction SilentlyContinue

    ))
    
    #####################
    #####################
    $CompiledResults.add('GetNetTcpConnection',$(
        Get-NetTcpConnection
    ))

    #####################
    #####################
    $CompiledResults.add('GetNetUDPEndpoint',$(
        Get-NetUDPEndpoint
    ))

    # Duplicate features...
        # Network Connections TCP
        #$GetNetStatTCP = "$Path\Get-NetStatTCP.ps1"
        #$GetNetStatTCPv6 = "$Path\Get-NetStatTCPv6.ps1"
        # Network Connections UDP
        #$GetNetStatUDP = "$Path\Get-NetStatUDP.ps1"
        #$GetNetStatUDPv6 = "$Path\Get-NetStatUDPv6.ps1"

    #####################
    #####################
    $CompiledResults.add('GetRegistryWirelessNetworks',$(
        function Get-WirelessNetworks {
            $RegistryPath     = "Registry::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\"
            $RegistryKeyNames = Get-ChildItem -Name $RegistryPath
            $Data = @()
            foreach ($Key in $RegistryKeyNames){
                $KeyPath = $RegistryPath + $Key
                $KeyProperty = Get-ItemProperty -Path $KeyPath

                $DateCreated = $KeyProperty.DateCreated
                  $DC_Hexes  = [System.BitConverter]::ToString($KeyProperty.datecreated) -split '-'
                  $DC_Year   = [Convert]::ToInt32($DC_Hexes[1]+$DC_Hexes[0],16)
                  $DC_Month  = [Convert]::ToInt32($DC_Hexes[3]+$DC_Hexes[2],16)
                  $DC_Day    = [Convert]::ToInt32($DC_Hexes[7]+$DC_Hexes[6],16)
                  $DC_Hour   = [Convert]::ToInt32($DC_Hexes[9]+$DC_Hexes[8],16)
                  $DC_Minute = [Convert]::ToInt32($DC_Hexes[11]+$DC_Hexes[10],16)
                  $DC_Second = [Convert]::ToInt32($DC_Hexes[13]+$DC_Hexes[12],16)
                  $DateCreatedFormatted = [datetime]"$DC_Month/$DC_Day/$DC_Year $DC_Hour`:$DC_Minute`:$DC_Second"

                $DateLastConnected = $KeyProperty.DateLastConnected
                  $DLC_Hexes  = [System.BitConverter]::ToString($KeyProperty.DateLastConnected) -split '-'
                  $DLC_Year   = [Convert]::ToInt32($DLC_Hexes[1]+$DLC_Hexes[0],16)
                  $DLC_Month  = [Convert]::ToInt32($DLC_Hexes[3]+$DLC_Hexes[2],16)
                  $DLC_Day    = [Convert]::ToInt32($DLC_Hexes[7]+$DLC_Hexes[6],16)
                  $DLC_Hour   = [Convert]::ToInt32($DLC_Hexes[9]+$DLC_Hexes[8],16)
                  $DLC_Minute = [Convert]::ToInt32($DLC_Hexes[11]+$DLC_Hexes[10],16)
                  $DLC_Second = [Convert]::ToInt32($DLC_Hexes[13]+$DLC_Hexes[12],16)
                  $DateLastConnectedFormatted = [datetime]"$DLC_Month/$DLC_Day/$DLC_Year $DLC_Hour`:$DLC_Minute`:$DLC_Second"

                $Data += [PSCustomObject]@{
		         "PSComputerName"   = $env:ComputerName
                    "SSID"             = $KeyProperty.Description
                    "ProfileName"      = $KeyProperty.ProfileName
                    "DateCreated"      = $DateCreatedFormatted
                    "DateLastConnected"= $DateLastConnectedFormatted
                }
            }
            $Data
        }
        Get-WirelessNetworks | Select-Object -Property PSComputerName, SSID, ProfileName, DateCreated, DateLastConnected
    ))

    #####################
    #####################
    $CompiledResults.add('GetIPConfigEnhanced',$(
        $GetNetAdapter = Get-NetAdapter | Select-Object -Property *

        $GetNetIPAddress = Get-NetIPAddress

        foreach ($NetAdapter in $GetNetAdapter) {
            foreach ($NetIPAddress in $GetNetIPAddress) {
                if ($NetAdapter.ifIndex -eq $NetIPAddress.ifIndex) {
                    $NetAdapter `
                    | Add-Member -MemberType NoteProperty -Name IPAddress     -Value $NetIPAddress.IPAddress     -Force -PassThru `
                    | Add-Member -MemberType NoteProperty -Name PrefixLength  -Value $NetIPAddress.PrefixLength  -Force -PassThru `
                    | Add-Member -MemberType NoteProperty -Name PrefixOrigin  -Value $NetIPAddress.PrefixOrigin  -Force -PassThru `
                    | Add-Member -MemberType NoteProperty -Name SuffixOrigin  -Value $NetIPAddress.SuffixOrigin  -Force -PassThru `
                    | Add-Member -MemberType NoteProperty -Name Type          -Value $NetIPAddress.Type          -Force -PassThru `
                    | Add-Member -MemberType NoteProperty -Name AddressFamily -Value $NetIPAddress.AddressFamily -Force -PassThru `
                    | Add-Member -MemberType NoteProperty -Name AddressState  -Value $NetIPAddress.AddressState  -Force -PassThru `
                    | Add-Member -MemberType NoteProperty -Name PolicyStore   -Value $NetIPAddress.PolicyStore   -Force
                }
            }
        }
        $GetNetAdapter | Select-Object -Property Name, InterfaceName, InterfaceDescription, Status, ConnectorPresent, Virtual, AddressFamily, IPAddress, Type, MacAddress, MediaConnectionState, PromiscuousMode, AdminStatus, MediaType, LinkSpeed, MtuSize, FullDuplex, AddressState, PrefixLength, PrefixOrigin, SuffixOrigin, DriverInformation, DriverProvider, DriverVersion, DriverDate, ifIndex, PolicyStore, Speed, ReceiveLinkSpeed, TransmitLinkSpeed, DeviceWakeUpEnable, AdminLocked, NotUserRemovable, ComponentID, HardwareInterface, Hidden, * -ErrorAction SilentlyContinue
    ))
    
    #####################
    #####################
    $CompiledResults.add('HostsFile',$(
        Get-Content C:\Windows\System32\drivers\etc\hosts
    ))

    #####################
    #####################
    $CompiledResults.add('GetPortProxy',$(
        $PortProxy = @()
        $netsh = & netsh interface portproxy show all
        $netsh | Select-Object -Skip 5 | Where-Object {$_ -ne ''} | ForEach-Object {
            $Attribitutes = $_ -replace "\s+"," " -split ' '
            $PortProxy += [PSCustomObject]@{
                'ComputerName'         = $Env:COMPUTERNAME
                'Listening On Address' = $Attribitutes[0]
                'Listening On Port'    = $Attribitutes[1]
                'Connect To Address'   = $Attribitutes[2]
                'Connect To Port'      = $Attribitutes[3]
            }
        }
        $PortProxy | Where-Object {$_.'Listening On Address' -match "\d.\d.\d.\d" -or $_.'Listening On Address' -match ':' }
    ))
        #netsh interface portproxy show all

    #####################
    #####################
    $CompiledResults.add('GetDnsClientCache',$(
        Get-DnsClientCache
    ))
        # ipconfig /displaydns

    #####################
    #####################
    $CompiledResults.add('GetVMNetworkAdapter',$(
        Get-VMNetworkAdapter -VMName *
    ))
        
    # Packet Capture    

#########################
### Process
#########################

    #####################
    #####################
    $CompiledResults.add('GetProcessesEnriched',$(
        $ErrorActionPreference = 'SilentlyContinue'
        $CollectionTime     = Get-Date
        $Processes          = Get-WmiObject Win32_Process
        $Services           = Get-WmiObject Win32_Service

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
                $Connection | Add-Member -MemberType NoteProperty OwningProcess $proc.ProcessId -Force
                $Connection | Add-Member -MemberType NoteProperty ParentProcessId $proc.ParentProcessId -Force
                $Connection | Add-Member -MemberType NoteProperty Name $proc.Caption -Force
                $Connection | Add-Member -MemberType NoteProperty ExecutablePath $proc.ExecutablePath -Force
                $Connection | Add-Member -MemberType NoteProperty CommandLine $proc.CommandLine -Force
                $Connection | Add-Member -MemberType NoteProperty PSComputerName $env:COMPUTERNAME -Force
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

        # Create Hashtable of all network processes and their PIDs
        $NetConnections = @{}
        foreach ( $Connection in $NetworkConnections ) {
            $connStr = "[$($Connection.State)] " + "$($Connection.LocalAddress)" + ";" + "$($Connection.LocalPort)" + " <--> " + "$($Connection.RemoteAddress)" + ";" + "$($Connection.RemotePort)" + " [$($Connection.CreationTime)]`n"
            if ( $Connection.OwningProcess -in $NetConnections.keys ) {
                if ( $connStr -notin $NetConnections[$Connection.OwningProcess] ) { $NetConnections[$Connection.OwningProcess] += $connStr }
            }
            else { $NetConnections[$Connection.OwningProcess] = $connStr }
        }

        # Create HashTable of services associated to PIDs
        $ServicePIDs = @{}
        foreach ( $svc in $Services ) {
            if ( $svc.ProcessID -notin $ServicePIDs.keys ) {
                $ServicePIDs[$svc.ProcessID] += "$($svc.name) [$($svc.Startmode) Start By $($svc.startname)]`n"
            }
        }

        # Create HashTable of Process Filepath's MD5Hash
        $MD5Hashtable = @{}
        foreach ( $Proc in $Processes ) {
            if ( $Proc.Path -and $Proc.Path -notin $MD5Hashtable.keys ) {
                $MD5Hashtable[$Proc.Path] += $(Get-FileHash -Path $Proc.Path -ErrorAction SilentlyContinue).Hash
            }
        }

        # Create HashTable of Process Filepath's Authenticode Signature Information
        $TrackPaths  = @()
        $AuthenCodeSigStatus            = @{}
        $AuthenCodeSigSignerCertificate = @{}
        $AuthenCodeSigSignerCompany     = @{}
        foreach ( $Proc in $Processes ) {
            if ( $Proc.Path -notin $TrackPaths ) {
                $TrackPaths += $Proc.Path
                $AuthenCodeSig = Get-AuthenticodeSignature -FilePath $Proc.Path -ErrorAction SilentlyContinue
                if ( $Proc.Path -notin $AuthenCodeSigStatus.keys ) { $AuthenCodeSigStatus[$Proc.Path] += $AuthenCodeSig.Status }
                if ( $Proc.Path -notin $AuthenCodeSigSignerCertificate.keys ) { $AuthenCodeSigSignerCertificate[$Proc.Path] += $AuthenCodeSig.SignerCertificate.Thumbprint }
                if ( $Proc.Path -notin $AuthenCodeSigSignerCompany.keys ) { $AuthenCodeSigSignerCompany[$Proc.Path] += $AuthenCodeSig.SignerCertificate.Subject.split(',')[0].replace('CN=','').replace('"','') }
            }
        }

        function Write-ProcessTree($Process) {
            $EnrichedProcess       = Get-Process -Id $Process.ProcessId

            $ProcessID             = $Process.ProcessID
            $ParentProcessID       = $Process.ParentProcessID
            $ParentProcessName     = $(Get-Process -Id $Process.ParentProcessID).Name
            $CommandLine           = $Process.CommandLine
            #$CreationDate         = $([Management.ManagementDateTimeConverter]::ToDateTime($Process.CreationDate))

            $ServiceInfo           = $ServicePIDs[$Process.ProcessId]

            $NetConns              = $($NetConnections[$Process.ProcessId]).TrimEnd("`n")
            $NetConnsCount         = if ($NetConns) {$($NetConns -split "`n").Count} else {[int]0}

            $MD5Hash               = $MD5Hashtable[$Process.Path]

            $StatusMessage         = $AuthenCodeSigStatus[$Process.Path]
            $SignerCertificate     = $AuthenCodeSigSignerCertificate[$Process.Path]
            $SignerCompany         = $AuthenCodeSigSignerCompany[$Process.Path]

            $Modules               = $EnrichedProcess.Modules.ModuleName
            $ModuleCount           = $Modules.count

            $ThreadCount           = $EnrichedProcess.Threads.count

            $Owner                 = $Process.GetOwner().Domain.ToString() + "\"+ $Process.GetOwner().User.ToString()
            $OwnerSID              = $Process.GetOwnerSid().Sid.ToString()
            $EnrichedProcess `
            | Add-Member NoteProperty 'ProcessID'              $ProcessID         -PassThru -Force `
            | Add-Member NoteProperty 'ParentProcessID'        $ParentProcessID   -PassThru -Force `
            | Add-Member NoteProperty 'ParentProcessName'      $ParentProcessName -PassThru -Force `
            | Add-Member NoteProperty 'CommandLine'            $CommandLine       -PassThru -Force `
            | Add-Member NoteProperty 'CreationDate'           $CreationDate      -PassThru -Force `
            | Add-Member NoteProperty 'ServiceInfo'            $ServiceInfo       -PassThru -Force `
            | Add-Member NoteProperty 'NetworkConnections'     $NetConns          -PassThru -Force `
            | Add-Member NoteProperty 'NetworkConnectionCount' $NetConnsCount     -PassThru -Force `
            | Add-Member NoteProperty 'StatusMessage'          $StatusMessage     -PassThru -Force `
            | Add-Member NoteProperty 'SignerCertificate'      $SignerCertificate -PassThru -Force `
            | Add-Member NoteProperty 'SignerCompany'          $SignerCompany     -PassThru -Force `
            | Add-Member NoteProperty 'MD5Hash'                $MD5Hash           -PassThru -Force `
            | Add-Member NoteProperty 'Modules'                $Modules           -PassThru -Force `
            | Add-Member NoteProperty 'ModuleCount'            $ModuleCount       -PassThru -Force `
            | Add-Member NoteProperty 'ThreadCount'            $ThreadCount       -PassThru -Force `
            | Add-Member NoteProperty 'Owner'                  $Owner             -PassThru -Force `
            | Add-Member NoteProperty 'OwnerSID'               $OwnerSID          -PassThru -Force
        }

        $Processes | Foreach-Object { Write-ProcessTree -Process $PSItem} | Select Name, ProcessID, ParentProcessName, ParentProcessID, ServiceInfo,`
        StartTime, @{Name='Duration';Expression={New-TimeSpan -Start $_.StartTime -End $CollectionTime}}, CPU, TotalProcessorTime, `
        NetworkConnections, NetworkConnectionCount, CommandLine, Path, `
        WorkingSet, @{Name='MemoryUsage';Expression={
            if     ($_.WorkingSet -gt 1GB) {"$([Math]::Round($_.WorkingSet/1GB, 2)) GB"}
            elseif ($_.WorkingSet -gt 1MB) {"$([Math]::Round($_.WorkingSet/1MB, 2)) MB"}
            elseif ($_.WorkingSet -gt 1KB) {"$([Math]::Round($_.WorkingSet/1KB, 2)) KB"}
            else                           {"$([Math]::Round($_.WorkingSet,     2)) Bytes"}
        }}, `
        MD5Hash, SignerCertificate, StatusMessage, SignerCompany, Company, Product, ProductVersion, Description, `
        Modules, ModuleCount, `
        @{n='Threads';e={([string]($_ | Select -Expand Threads | Select -Expand id)).Split() -Join',' }}, `
        ThreadCount, Handle, Handles, HandleCount, `
        Owner, OwnerSID    
    ))

    #####################
    #####################
    $CompiledResults.add('GetLoadedDLLs',$(
	    $results = Get-Process | Select-Object -ExpandProperty Modules -ErrorAction SilentlyContinue | Sort-Object FileName -Unique | ForEach-Object {
		    if ($_.FileName -ne $null) {
			    $md5  = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
			    $hash = [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($_.FileName)))
			    $_ | Add-Member -MemberType NoteProperty MD5 $($hash -replace "-","")
		    }
		    else {
			    $_ | Add-Member -MemberType NoteProperty MD5 $null
		    }
		    $_
	    }
	    $results | Select-Object -Property ModuleName,FileName,MD5,Size,Company,Description,FileVersion,Product,ProductVersion
    ))

#########################
### Service
#########################

    #####################
    #####################
    $CompiledResults.add('GetServicesEnriched',$(
        $service = Get-WmiObject -Class Win32_Service

        foreach ($svc in $service) {
            $ProcessName = Get-Process -Id $svc.processid | Select-Object -ExpandProperty Name
            $svc | Add-member -NotePropertyName 'ProcessName' -NotePropertyValue $ProcessName
        }
        $service | Select-Object PSComputerName, Name, State, Status, Started, StartMode, StartName, ProcessID, ProcessName,  PathName, Caption, Description, DelayedAutoStart, AcceptPause, AcceptStop
    ))

#########################
### Login Activity
#########################

    #####################
    #####################
    $CompiledResults.add('GetAccountsCurrentlyLoggedOnInteractively',$(
        ## Find all sessions matching the specified username
        $quser = quser | Where-Object {$_ -notmatch 'SESSIONNAME'}

        $sessions = ($quser -split "`r`n").trim()

        foreach ($session in $sessions) {
            try {
                # This checks if the value is an integer, if it is then it'll TRY, if it errors then it'll CATCH
                [int]($session -split '  +')[2] | Out-Null

                [PSCustomObject]@{
                    PSComputerName = $env:COMPUTERNAME
                    UserName       = ($session -split '  +')[0].TrimStart('>')
                    SessionName    = ($session -split '  +')[1]
                    SessionID      = ($session -split '  +')[2]
                    State          = ($session -split '  +')[3]
                    IdleTime       = ($session -split '  +')[4]
                    LogonTime      = ($session -split '  +')[5]
                }
            }
            catch {
                [PSCustomObject]@{
                    PSComputerName = $env:COMPUTERNAME
                    UserName       = ($session -split '  +')[0].TrimStart('>')
                    SessionName    = ''
                    SessionID      = ($session -split '  +')[1]
                    State          = ($session -split '  +')[2]
                    IdleTime       = ($session -split '  +')[3]
                    LogonTime      = ($session -split '  +')[4]
                }
            }
        }
    ))
        #Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount='True'"

    #####################
    #####################
    $CompiledResults.add('Win32_NetworkLoginProfile',$(
        Get-WmiObject -Class Win32_NetworkLoginProfile | Select-Object -Property *
    ))

    #####################
    #####################
    $CompiledResults.add('',$())
    $GetLoginsFailed = "$Path\Get-LoginsFailed.ps1"

    #####################
    #####################
    $CompiledResults.add('',$())
    $GetCurrentLoginActivity = Get-WSManInstance -ResourceURI Shell -Enumerate

    # Event Logs

    # Current PSSessions

    # Current RDP

    # Share Access

#########################
### Event Logs
#########################

    #####################
    #####################
    $CompiledResults.add('GetEventLogList',$(
        Get-EventLog -List
    ))

    #####################
    #####################
    $CompiledResults.add('GetWinEventListLog',$(
        Get-WinEvent -ListLog *
    ))

    #####################
    #####################
    $CompiledResults.add('GetLoginEventsLast24hrs',$(
        Function Get-LoginEvents {
            Param (
                [Parameter(
                    ValueFromPipeline = $true,
                    ValueFromPipelineByPropertyName = $true
                )]
                [Alias('Name')]
                [string]$ComputerName = $env:ComputerName
                ,
                [datetime]$StartTime
                ,
                [datetime]$EndTime
            )
            Begin {
                enum LogonTypes {
                    LocalSystem       = 0
                    Interactive       = 2
                    Network           = 3
                    Batch             = 4
                    Service           = 5
                    Unlock            = 7
                    NetworkClearText  = 8
                    NewCredentials    = 9
                    RemoteInteractive = 10
                    CachedInteractive = 11
                }
                enum LogonDescription {
                    LocalSystem                    = 0
                    LocalLogon                     = 2
                    RemoteLogon                    = 3
                    ScheduledTask                  = 4
                    ServiceAccountLogon            = 5
                    ScreenSaver                    = 7
                    CLeartextNetworkLogon          = 8
                    RusAsUsingAlternateCredentials = 9
                    RDP_TS_RemoteAssistance        = 10
                    LocalWithCachedCredentials     = 11
                }

                $FilterHashTable = @{
                    LogName   = 'Security'
                    ID        = 4624
                }
                if ($PSBoundParameters.ContainsKey('StartTime')){
                    $FilterHashTable['StartTime'] = $StartTime
                }
                if ($PSBoundParameters.ContainsKey('EndTime')){
                    $FilterHashTable['EndTime'] = $EndTime
                }
            }
            Process {
                Get-WinEvent -ComputerName $ComputerName -FilterHashtable $FilterHashTable | ForEach-Object {
                    [pscustomobject]@{
                        ComputerName         = $ComputerName
                        UserAccount          = $_.Properties.Value[5]
                        UserDomain           = $_.Properties.Value[6]
                        LogonType            = [LogonTypes]$_.Properties.Value[8]
                        LogonDescription     = [LogonDescription]$_.Properties.Value[8]
                        WorkstationName      = $_.Properties.Value[11]
                        SourceNetworkAddress = $_.Properties.Value[19]
                        TimeStamp            = $_.TimeCreated
                    }
                }
            }
            End{}
        }
        Get-LoginEvents -StartTime $([datetime]::Today.AddHours(-24)) -EndTime $([datetime]::Today)    
    ))

    # Last 1000 Security

    # Last 1000 System

    # Last 1000 ...


#########################
### Registry
#########################

    #... something something darkside

#########################
### Hardware
#########################

    #####################
    #####################
    $CompiledResults.add('GetDriverDetails',$(
        # Gets Driver Details, MD5 Hash, and File Signature Status
        # This script can be quite time consuming
        $Drivers = Get-WindowsDriver -Online -All
        $MD5     = [System.Security.Cryptography.HashAlgorithm]::Create("MD5")
        $SHA256  = [System.Security.Cryptography.HashAlgorithm]::Create("SHA256")

        foreach ($Driver in $Drivers) {
            $filebytes = [system.io.file]::ReadAllBytes($($Driver).OriginalFilename)

            $HashMD5 = [System.BitConverter]::ToString($MD5.ComputeHash($filebytes)) -replace "-", ""
            $Driver | Add-Member -NotePropertyName HashMD5 -NotePropertyValue $HashMD5

            # If enbaled, add HashSHA256 to Select-Object
            #$HashSHA256 = [System.BitConverter]::ToString($SHA256.ComputeHash($filebytes)) -replace "-", ""
            #$Driver | Add-Member -NotePropertyName HashSHA256 -NotePropertyValue $HashSHA256

            $FileSignature = Get-AuthenticodeSignature -FilePath $Driver.OriginalFileName
            $Signercertificate = $FileSignature.SignerCertificate.Thumbprint
            $Driver | Add-Member -NotePropertyName SignerCertificate -NotePropertyValue $Signercertificate
            $Status = $FileSignature.Status
            $Driver | Add-Member -NotePropertyName Status -NotePropertyValue $Status
            $Driver | Select-Object -Property @{name="PSComputerName";expression={$env:COMPUTERNAME}}, Online, ClassName, Driver, OriginalFileName, ClassDescription, BootCritical, HashMD5, DriverSignature, SignerCertificate, Status, ProviderName, Date, Version, InBox, LogPath, LogLevel
        }
    ))
        #Get-WindowsDriver -Online -All #<-- included in the above script

    #####################
    #####################
    $CompiledResults.add('Win32_Systemdriver',$(
        Get-WmiObject -Class Win32_Systemdriver
    ))
        # driverquery /si /FO csv

    #####################
    #####################
    $CompiledResults.add('Win32_BaseBoard',$(
        Get-WmiObject -Class Win32_BaseBoard
    ))

    #####################
    #####################
    $CompiledResults.add('GetLogicalDisksEnriched',$(
        function Get-LogicalMappedDrives{
            Get-WmiObject -Class Win32_LogicalDisk |
                Select-Object -Property @{Name='ComputerName';Expression={$($env:computername)}},
                @{Name='Name';Expression={$_.DeviceID}},
                    DeviceID, DriveType,
                @{Name = 'DriveTypeName'
                    Expression = {
                        if     ($_.DriveType -eq 0) {'Unknown'}
                        elseif ($_.DriveType -eq 1) {'No Root Directory'}
                        elseif ($_.DriveType -eq 2) {'Removeable Disk'}
                        elseif ($_.DriveType -eq 3) {'Local Drive'}
                        elseif ($_.DriveType -eq 4) {'Network Drive'}
                        elseif ($_.DriveType -eq 5) {'Compact Disc'}
                        elseif ($_.DriveType -eq 6) {'RAM Disk'}
                        else                        {'Error: Unknown'}
                    }}, VolumeName,
                @{L='FreeSpaceGB';E={"{0:N2}" -f ($_.FreeSpace /1GB)}},
                @{L="CapacityGB";E={"{0:N2}" -f ($_.Size/1GB)}},
                FileSystem, VolumeSerialNumber, 
                Compressed, SupportsFileBasedCompression,
                SupportsDiskQuotas, QuotasDisabled, QuotasIncomplete, QuotasRebuilding
        }
        Get-LogicalMappedDrives    
    ))
        # Get-WmiObject -Class Win32_LogicalDisk #<-- Used within script above

    #####################
    #####################
    $CompiledResults.add('GetDisk',$(
        Get-Disk | Select-Object -Property Number, FriendlyName, OperationalStatus, BusType, SerialNumber, HealthStatus, @{n='TotalSize';e={"$([Math]::Round($_.Size/1GB,2)) GB"}}, OperationalStatus, PartitionStyle, BootFromDisk, IsBoot, IsClustered, IsHighlyAvailable, Location, IsOffline, IsReadonly, IsScaleout, IsSystem, * -ErrorAction SilentlyContinue
    ))
        # Get-WmiObject -Class Win32_DiskDrive #<-- similar to above command

    #####################
    #####################
    $CompiledResults.add('Win32_Processor',$(
        Get-WmiObject -Class Win32_Processor | Select-Object -Property *
    ))

    #####################
    #####################
    $CompiledResults.add('Win32_PhysicalMemory',$(
        Get-WmiObject -Class Win32_PhysicalMemory | Select-Object -Property *
    ))

    #####################
    #####################
    $CompiledResults.add('Win32_PerfRawData_PerfOS_Memory',$(
        Get-WmiObject -Class Win32_PerfRawData_PerfOS_Memory
    ))

    #####################
    #####################
    $CompiledResults.add('Win32_BIOS',$(
        Get-WmiObject -Class Win32_BIOS
    ))

    #####################
    #####################
    $CompiledResults.add('',$(
        Get-WmiObject -Class Win32_USBControllerDevice | Foreach-Object {
            $Dependent  = [wmi]($_.Dependent)
            $Antecedent = [wmi]($_.Antecedent)

            [PSCustomObject]@{
                USBDeviceName             = $Dependent.Name
                USBDeviceManufacturer     = $Dependent.Manufacturer
                USBDeviceService          = $Dependent.Service
                USBDeviceStatus           = $Dependent.Status
                USBDevicePNPDeviceID      = $Dependent.PNPDeviceID
                USBDeviceHardwareID       = $Dependent.HardwareID
                USBDeviceInstallDate      = $Dependent.InstallDate
                USBControllerName         = $Antecedent.Name
                USBControllerManufacturer = $Antecedent.Manufacturer
                USBControllerStatus       = $Antecedent.Status
                USBControllerPNPDeviceID  = $Antecedent.PNPDeviceID
                USBControllerInstallDate  = $Antecedent.InstallDate
            }
        } `
        | Select-Object -Property PSComputerName, * -ErrorAction SilentlyContinue `
        | Sort-Object Description,DeviceID
    ))
    $GetUSBControllerAndDevices = "$Path\Get-USBControllerAndDevices.ps1"
        # Get-WmiObject -Class Win32_USBControllerDevice #<-- Included in the above script
    
    #####################
    #####################
    $CompiledResults.add('GetPnpDevice',$(
        Get-PnpDevice | Select-Object -Property Status, Class, Name, Description, Manufacturer, PNPClass, Present, Service,  InstanceId, DeviceID, HardwareID, * -ErrorAction SilentlyContinue
    ))
        # Get-WmiObject -Class Win32_PnPEntity #<-- Similar to above

    #####################
    #####################
    $CompiledResults.add('USBHistory',$(
        Get-ItemProperty -Path HKLM:\system\CurrentControlSet\Enum\USBSTOR\*\*
    ))

    #####################
    #####################
    $CompiledResults.add('Win32_Printer',$(
        Get-WmiObject -Class Win32_Printer
    ))

#########################
### Software
#########################

    #####################
    #####################
    $CompiledResults.add('',$(
        $Software = @()
        $Paths    = @("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall","SOFTWARE\\Wow6432node\\Microsoft\\Windows\\CurrentVersion\\Uninstall")
        ForEach($Path in $Paths) {
        Write-Verbose  "Checking Path: $Path"
        #  Create an instance of the Registry Object and open the HKLM base key
        Try  {$reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$env:Computername,'Registry64')}
        Catch  {Write-Error $_ ; Continue}
        #  Drill down into the Uninstall key using the OpenSubKey Method
        Try  {
	        $regkey=$reg.OpenSubKey($Path)
	        # Retrieve an array of string that contain all the subkey names
	        $subkeys=$regkey.GetSubKeyNames()
	        # Open each Subkey and use GetValue Method to return the required  values for each
	        ForEach ($key in $subkeys){
		        Write-Verbose "Key: $Key"
		        $thisKey=$Path+"\\"+$key
		        Try {
			        $thisSubKey=$reg.OpenSubKey($thisKey)
			        # Prevent Objects with empty DisplayName
			        $DisplayName =  $thisSubKey.getValue("DisplayName")
			        If ($DisplayName  -AND $DisplayName  -notmatch '^Update  for|rollup|^Security Update|^Service Pack|^HotFix') {
				        $Date = $thisSubKey.GetValue('InstallDate')
				        If ($Date) {
					        Try {$Date = [datetime]::ParseExact($Date, 'yyyyMMdd', $Null)}
					        Catch{Write-Warning "$($env:Computername): $_ <$($Date)>" ; $Date = $Null}
				        }
				        # Create New Object with empty Properties
				        $Publisher =  Try {$thisSubKey.GetValue('Publisher').Trim()}
					        Catch {$thisSubKey.GetValue('Publisher')}
				        $Version = Try {
					        #Some weirdness with trailing [char]0 on some strings
					        $thisSubKey.GetValue('DisplayVersion').TrimEnd(([char[]](32,0)))
				        }
					        Catch {$thisSubKey.GetValue('DisplayVersion')}
				        $UninstallString =  Try {$thisSubKey.GetValue('UninstallString').Trim()}
					        Catch {$thisSubKey.GetValue('UninstallString')}
				        $InstallLocation =  Try {$thisSubKey.GetValue('InstallLocation').Trim()}
					        Catch {$thisSubKey.GetValue('InstallLocation')}
				        $InstallSource =  Try {$thisSubKey.GetValue('InstallSource').Trim()}
					        Catch {$thisSubKey.GetValue('InstallSource')}
				        $HelpLink = Try {$thisSubKey.GetValue('HelpLink').Trim()}
					        Catch {$thisSubKey.GetValue('HelpLink')}
				        $Object = [pscustomobject]@{
					        Computername = $env:Computername
					        DisplayName = $DisplayName
					        Version  = $Version
					        InstallDate = $Date
					        Publisher = $Publisher
					        UninstallString = $UninstallString
					        InstallLocation = $InstallLocation
					        InstallSource  = $InstallSource
					        HelpLink = $thisSubKey.GetValue('HelpLink')
					        EstimatedSizeMB = [decimal]([math]::Round(($thisSubKey.GetValue('EstimatedSize')*1024)/1MB,2))
				        }
				        $Object.pstypenames.insert(0,'System.Software.Inventory')
				        $Software += $Object
				        }
			        }
			        Catch {Write-Warning "$Key : $_"}
		        }
	        }
	        Catch  {}
	        $reg.Close()
        }
        $Software
    ))
    $GetRegistrySoftware = "$Path\Get-RegistrySoftware.ps1"

    #####################
    #####################
    $CompiledResults.add('Win32_Product',$(
        Get-WmiObject -Class Win32_Product | Select-Object Name, Caption, Vendor, Version, InstallDate, @{n='InstallDateTime';e={[datetime]::parseexact($_.InstallDate, 'yyyyMMdd', $null)}}, IdentifyingNumber, InstallSource, InstallLocation, LocalPackage, PackageName, HelpLink, URLInfoAbout, URLUpdateInfo, HelpTelephone, Language, ProductID, RegCompany, RegOwner, SKUNumber, Transforms
    ))
   
    # Date installed

    # Manufacturer

    #####################
    #####################
    $CompiledResults.add('GetCrashedApplications',$(
        $Faults = Get-EventLog -LogName Application -InstanceId 1000 | Select-Object -ExpandProperty Message
        $UniqueFault = @()
        ForEach ($f in $Faults) {
            $fault = if ($f -match 'Faulting'){$f.split(':')[1].split(',')[0].trim()}
            if ($fault -notin $UniqueFault) { $UniqueFault += $fault }
        }
        $UniqueFault
    ))

#########################
### Security
#########################

    #####################
    #####################
    $CompiledResults.add('',$(
        $regConfig = @"
        RegistryKey,Name
        "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa","scenoapplylegacyauditpolicy"
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit","ProcessCreationIncludeCmdLine_Enabled"
        "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription","EnableTranscripting"
        "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription","OutputDirectory"
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging","EnableScriptBlockLogging"
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging","EnableModuleLogging"
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\EventForwarding\SubscriptionManager",1
        "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest","UseLogonCredential"
        "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Credssp\PolicyDefaults","Allow*"
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation","Allow*"
"@

        $regConfig | ConvertFrom-Csv | ForEach-Object {
	        if (-Not (Test-Path $_.RegistryKey)) {
		        # Registry path does not exist -> document DNE
		        New-Object PSObject -Property @{RegistryKey = $_.RegistryKey; Name = $_.Name; Value = "Does Not Exist"}
	        }
	        else {
		        if ((Get-ItemProperty $_.RegistryKey | Select-Object -Property $_.Name).$_.Name -ne $null) {
			        # Registry key exists. Document Value
			        # Handle Cases where SubscriptionManager Value already exists.
			        if ($_.RegistryKey -like "*SubscriptionManager*") {
				        $wecNum = 1
				        # Backup each currently configured SubscriptionManager Values.
				        while ( (Get-ItemProperty $_.RegistryKey | Select-Object -ExpandProperty $([string]$wecNum) -ErrorAction SilentlyContinue) ) {
					        #Write-Warning "RegistryKey with property = $wecNum exists"
					        New-Object PSObject -Property @{RegistryKey = $_.RegistryKey; Name = $wecNum; Value = $(Get-ItemProperty $_.RegistryKey | Select-Object -ExpandProperty $([string]$wecNum))}
					        #Write-Warning "Incrementing wecNum"
					        $wecNum++
				        }
			        }
			        # Backup all non-SubscriptionManager Values to array.
			        else {
				        New-Object PSObject -Property @{RegistryKey = $_.RegistryKey; Name = $_.Name; Value = $(Get-ItemProperty $_.RegistryKey | Select-Object -ExpandProperty $_.Name)}
			        }
		        }
		        else {
			        # Registry key does not exist. Document DNE
			        New-Object PSObject -Property @{RegistryKey = $_.RegistryKey; Name = $_.Name; Value = "Does Not Exist"}
		        }
	        }
        }
    ))
    $GetAuditOptions = "$Path\Get-AuditOptions.ps1"

    #####################
    #####################
    $CompiledResults.add('auditpol',$(
        auditpol /get /category:* /r | Convertfrom-Csv
    ))

    # System Info
        #........need to parse for potential useful data

    #####################
    #####################
    $CompiledResults.add('GetHotFix',$(
        Get-HotFix
    ))
        #Get-WmiObject -Class Win32_QuickFixEngineering #<-- similar to above

    #####################
    #####################
    $CompiledResults.add('GetSecureBootPolicy',$(
        Get-SecureBootPolicy
    ))

    #####################
    #####################
    $CompiledResults.add('ConfirmSecureBootUEFI',$(
        Confirm-SecureBootUEFI
    ))

    #####################
    #####################
    $CompiledResults.add('GetMpThreat',$(
        Get-MpThreat
    ))

    #####################
    #####################
    $CompiledResults.add('GetMpThreatDetection',$(
        Get-MpThreatDetection
    ))

    #####################
    #####################
    $CompiledResults.add('GetMpPreference',$(
        Get-MpPreference
    ))

    #####################
    #####################
    $CompiledResults.add('GetMpComputerStatus',$(
        Get-MpComputerStatus
    ))

    #####################
    #####################
    $CompiledResults.add('AntivirusProduct',$(
        Get-WmiObject -Namespace root\SecurityCenter2 -Class AntivirusProduct
    ))

#########################
### Firewall
#########################

    #####################
    #####################
    $CompiledResults.add('GetFirewallRulesEnriched',$(
        function Get-EnrichedFirewallRules {
            Param(
                $Name = "*",
                [switch]$Verbose
            )
            # convert Stringarray to comma separated liste (String)
            function StringArrayToList($StringArray) {
                if ($StringArray) {
                    $Result = ""
                    Foreach ($Value In $StringArray) {
                        if ($Result -ne "") { $Result += "," }
                        $Result += $Value
                    }
                    return $Result
                }
                else {
                    return ""
                }
            }
            $FirewallRules = Get-NetFirewallRule -DisplayName $Name -PolicyStore "ActiveStore"
            $FirewallRuleSet = @()
            ForEach ($Rule In $FirewallRules) {
                if ($Verbose) { Write-Output "Processing rule `"$($Rule.DisplayName)`" ($($Rule.Name))" }

                $AdressFilter        = $Rule | Get-NetFirewallAddressFilter
                $PortFilter          = $Rule | Get-NetFirewallPortFilter
                $ApplicationFilter   = $Rule | Get-NetFirewallApplicationFilter
                $ServiceFilter       = $Rule | Get-NetFirewallServiceFilter
                $InterfaceFilter     = $Rule | Get-NetFirewallInterfaceFilter
                $InterfaceTypeFilter = $Rule | Get-NetFirewallInterfaceTypeFilter
                $SecurityFilter      = $Rule | Get-NetFirewallSecurityFilter

                # Created Enriched Object
                $HashProps = [PSCustomObject]@{
                    Name                = $Rule.Name
                    DisplayName         = $Rule.DisplayName
                    Description         = $Rule.Description
                    Group               = $Rule.Group
                    Enabled             = $Rule.Enabled
                    Profile             = $Rule.Profile
                    Platform            = StringArrayToList $Rule.Platform
                    Direction           = $Rule.Direction
                    Action              = $Rule.Action
                    EdgeTraversalPolicy = $Rule.EdgeTraversalPolicy
                    LooseSourceMapping  = $Rule.LooseSourceMapping
                    LocalOnlyMapping    = $Rule.LocalOnlyMapping
                    Owner               = $Rule.Owner
                    LocalAddress        = StringArrayToList $AdressFilter.LocalAddress
                    RemoteAddress       = StringArrayToList $AdressFilter.RemoteAddress
                    Protocol            = $PortFilter.Protocol
                    LocalPort           = StringArrayToList $PortFilter.LocalPort
                    RemotePort          = StringArrayToList $PortFilter.RemotePort
                    IcmpType            = StringArrayToList $PortFilter.IcmpType
                    DynamicTarget       = $PortFilter.DynamicTarget
                    Program             = $ApplicationFilter.Program -Replace "$($ENV:SystemRoot.Replace("\","\\"))\\", "%SystemRoot%\" -Replace "$(${ENV:ProgramFiles(x86)}.Replace("\","\\").Replace("(","\(").Replace(")","\)"))\\", "%ProgramFiles(x86)%\" -Replace "$($ENV:ProgramFiles.Replace("\","\\"))\\", "%ProgramFiles%\"
                    Package             = $ApplicationFilter.Package
                    Service             = $ServiceFilter.Service
                    InterfaceAlias      = StringArrayToList $InterfaceFilter.InterfaceAlias
                    InterfaceType       = $InterfaceTypeFilter.InterfaceType
                    LocalUser           = $SecurityFilter.LocalUser
                    RemoteUser          = $SecurityFilter.RemoteUser
                    RemoteMachine       = $SecurityFilter.RemoteMachine
                    Authentication      = $SecurityFilter.Authentication
                    Encryption          = $SecurityFilter.Encryption
                    OverrideBlockRules  = $SecurityFilter.OverrideBlockRules
                }
                $FirewallRuleSet += $HashProps
            }
            return $FirewallRuleSet
        }
        Get-EnrichedFirewallRules    
    ))
        #netsh advfirewall firewall show rule name=all

    #####################
    #####################
    $CompiledResults.add('GetNetFirewallProfile',$(
        Get-NetFirewallProfile
    ))
        #netsh advfirewall show allprofiles state

#########################
### Accounts / Groups
#########################

    #####################
    #####################
    $CompiledResults.add('GetLocalUser',$(
        Get-LocalUser | Select-Object -Property *
    ))
        # net user

    #####################
    #####################
    $CompiledResults.add('GetNonLocalUser',$(
        Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount='False'"
    ))

    #####################
    #####################
    $CompiledResults.add('GetLocalGroup',$(
        Get-LocalGroup | Select-Object -Property *
    ))
        # net localgroup

    #####################
    #####################
    $CompiledResults.add('GetNonLocalGroup',$(
        Get-WmiObject -Class Win32_Group -Filter { LocalAccount='False' }
    ))

    #####################
    #####################
    $CompiledResults.add('GetLocalGroupAdministrators',$(
        Get-LocalGroupMember -Group administrators
    ))
        # net localgroup administrators

#########################
### Shares
#########################

    #####################
    #####################
    $CompiledResults.add('GetSmbConnection',$(
        Get-SmbConnection | Select-Object -Property *
    ))

    #####################
    #####################
    $CompiledResults.add('GetSmbShare',$(
        Get-SmbShare | Foreach-Object {Get-SmbShareAccess -Name $_.Name} | Select-Object -Property *
    ))
        # Get-WmiObject -Class Win32_Share #<-- Similar to above

    #####################
    #####################
    $CompiledResults.add('GetSmbMapping',$(
        Get-SmbMapping | Select-Object -Property *
    ))

    #####################
    #####################
    $CompiledResults.add('GetSmbOpenFile',$(
        Get-SmbOpenFile | Select-Object -Property *
    ))

    #####################
    #####################
    $CompiledResults.add('GetSmbSession',$(
        Get-SmbSession | Select-Object -Property *
    ))

    #####################
    #####################
    $CompiledResults.add('GetSmbShare',$(
        Get-SmbShare | Select-Object -Property *
    ))

#########################
### Startup
#########################

    #####################
    #####################
    $CompiledResults.add('',$(
        $ErrorActionPreference = 'SilentlyContinue'

        $SHA256  = [System.Security.Cryptography.HashAlgorithm]::Create("SHA256")
        $MD5     = [System.Security.Cryptography.HashAlgorithm]::Create("MD5")
            $regkeys = @(
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunServices',
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce',
            'HCCU:\Software\Microsoft\Windows\Curre ntVersion\RunOnce\Setup',
            'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon',
            'HKLM:\Software\Microsoft\Active Setup\Installed Components',
            'HKLM:\System\CurrentControlSet\Servic es\VxD',
            'HKCU:\Control Panel\Desktop',
            'HKLM:\System\CurrentControlSet\Control\Session Manager',
            'HKLM:\System\CurrentControlSet\Services',
            'HKLM:\System\CurrentControlSet\Services\Winsock2\Parameters\Protocol_Catalog\Catalog_Entries',
            'HKLM:\System\Control\WOW\cmdline',
            'HKLM:\System\Control\WOW\wowcmdline',
            'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Userinit',
            'HKLM:\Software\Microsoft\Windows\Curr entVersion\ShellServiceObjectDelayLoad',
            'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows\run',
            'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows\load',
            'HKCU:\Software\Microsoft\Windows\Curre ntVersion\Policies\Explorer\run',
            'HLKM:\Software\Microsoft\Windows\Curr entVersion\Policies\Explorer\run'
        )
        $Startups = @()
        foreach ($key in $regkeys) {
            $entry = Get-ItemProperty -Path $key
            $entry = $entry | Select-Object * -ExcludeProperty PSPath, PSParentPath, PSChildName, PSDrive, PSProvider
            #$entry.psobject.Properties |ft
            foreach($item in $entry.PSObject.Properties) {
                $value = $item.value.replace('"', '')
                # The entry could be an actual path
                if(Test-Path $value) {

                    $filebytes   = [system.io.file]::ReadAllBytes($value)
                    $AuthenticodeSignature = Get-AuthenticodeSignature $value
                    $HashObject  = New-Object PSObject -Property @{
                        Name     = Split-Path $Value -Leaf
                        Path     = $value
                        SignatureStatus = $AuthenticodeSignature.Status
                        SignatureCompany = ($AuthenticodeSignature.SignerCertificate.SubjectName.Name -split ',')[0].TrimStart('CN=')
                        MD5      = [System.BitConverter]::ToString($md5.ComputeHash($filebytes)) -replace "-", "";
                        SHA256   = [System.BitConverter]::ToString($sha256.ComputeHash($filebytes)) -replace "-","";
                        PSComputerName = $env:COMPUTERNAME
                    }
                    $Startups += $HashObject
                }
            }
        }
        $Startups | Select-Object -Property Name, Path, MD5, SHA256, SignatureStatus, SignatureCompany    
    ))
    $GetRegistryStartupCommands = "$Path\Get-RegistryStartupCommands.ps1"
    
    #####################
    #####################
    $CompiledResults.add('Win32_StartupCommand',$(
        Get-WmiObject -Class Win32_StartupCommand
    ))

#########################
### PowerShell
#########################

    #####################
    #####################
    $CompiledResults.add('TestWSMan',$(
        Test-WSMan | Select-Object -Property *
    ))

    #####################
    #####################
    $CompiledResults.add('GetServiceWinRM',$(
        Get-Service -Name WinRM | Select-Object -Property *
    ))

    #####################
    #####################
    $CompiledResults.add('WSManTrustedHosts',$(
        Get-Item WSMan:\localhost\Client\TrustedHosts
    ))

    #####################
    #####################
    $CompiledResults.add('PSReadLineHistoryUserHistoryy',$(
        Get-Content (Get-PSReadLineOption | Select-Object -ExpandProperty HistorySavePath)
    ))

    $CompiledResults.add('PSReadLineHistoryConsoleHost',$(
        Get-Content "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
    ))

    #####################
    #####################
    $CompiledResults.add('PowerShellSessions',$(
        Get-WSManInstance -ResourceURI Shell -Enumerate | Select-Object -Property *
    ))

    #####################
    #####################
    $CompiledResults.add('GetCommand',$(
        Get-Command
    ))

    #####################
    #####################
    $CompiledResults.add('GetInstalledModule',$(
        Get-InstalledModule
    ))

    #####################
    #####################
    $CompiledResults.add('GetModule',$(
        Get-Module
    ))

    #####################
    #####################
    $CompiledResults.add('PSProfileAllUsersAllHosts',$(
        Get-Content $Profile.AllUsersAllHosts
    ))

    #####################
    #####################
    $CompiledResults.add('PSProfileAllUsersCurrentHost',$(
        Get-Content $Profile.AllUsersCurrentHost
    ))

    #####################
    #####################
    $CompiledResults.add('PSProfileCurrentUserAllHosts',$(
        Get-Content $Profile.CurrentUserAllHosts
    ))

    #####################
    #####################
    $CompiledResults.add('PSProfileCurrentUserCurrentHost',$(
        Get-Content $Profile.CurrentUserCurrentHost
    ))

    #####################
    #####################
    $CompiledResults.add('GetPowerShellHistory',$(
        $Users = Get-ChildItem C:\Users | Where-Object {$_.PSIsContainer -eq $true}

        $Results = @()
        Foreach ($User in $Users) {
            $UserPowerShellHistoryPath = "$($User.FullName)\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
            if (Test-Path $UserPowerShellHistoryPath) {
                $count = 1
                $UserHistory += Get-Content "$UserPowerShellHistoryPath" -ErrorAction Stop | ForEach-Object {"$_ `r`n"}
                foreach ($HistoryEntry in $UserHistory) {
                    $Results += [PSCustomObject]@{
                        PSComputerName    = "$env:COMPUTERNAME"
                        HistoryCount      = "$Count"
                        ProfileName       = "$($User.Name)"
                        PowerShellHistory = "$HistoryEntry"
                        ProfilePath       = "$($User.FullName)"
                        HistoryPath       = "$UserPowerShellHistoryPath"
                    }
                    $Count += 1
                }
            }
            else {
                $Results += [PSCustomObject]@{
                    PSComputerName    = "$env:COMPUTERNAME"
                    HistoryCount      = "0"
                    ProfileName       = "$($User.Name)"
                    PowerShellHistory = "There is not PowerShell History for $($User.BaseName)."
                    ProfilePath       = "$($User.FullName)"
                    HistoryPath       = "$UserPowerShellHistoryPath"
                }
            }
        }
        $Results    
    ))

#########################
### SRUM Dump
#########################

    function Invoke-SRUMDump {
        <#
            .SYNOPSIS
                Invoke-SRUMDump is a pure PowerShell/ .Net capability that enables the dumping of the System Resource Utilization Management (SRUM) database for CSVs. The database generally 
                contains 30 days of information that is vital to incident response and forensics.

            .NOTES  
                Modified By    : high101bro (modified for PoSh-EasyWin compatibility)
                Modified Date  : 26 August 21

                File Name      : Invoke-SRUMDump.ps1
                Version        : v.0.2
                Author         : @WiredPulse
                Created        : 20 May 21
        #>

        [CmdletBinding()]
        param(
               [parameter(ParameterSetName="set1")] [switch]$Live,
               [parameter(ParameterSetName="set2")] [switch]$Offline,
               [parameter(ParameterSetName="set2", Mandatory=$true)] $Hive,
               [parameter(ParameterSetName="set2", Mandatory=$true)] $Srum,
               $ExportDir = "$env:USERPROFILE\desktop\srum"
        )


        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if(-not($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))){
            throw "Error: This script needs to be ran as a user with Administrator rights"
        }

        [string]$date = Get-Date -UFormat %m-%d-%Y
        $ExportDir = $ExportDir+'_'+$date

        if(-not(test-path $ExportDir)){
            new-item $ExportDir -ItemType Directory | out-null
        }

        if($live){
            if(test-path C:\Windows\System32\sru\SRUDB.dat){
                copy-item C:\Windows\System32\sru\SRUDB.dat $ExportDir
                $path = "$exportdir\SRUDB.dat"
                if(-not(test-path $path)){
                    throw "Error: SrumDB couldn't be copied"
                }
            }
            else{
                throw "ERROR: SrumDB doesn't exist in C:\windows\system32\sru"
            }
        }
        else{
            $path = $Srum
            if(-not(test-path $srum)){
                throw "Error: SrumDB file doesn't exist at the specified path"
            }
            if(-not(test-path $hive)){
                throw "Error: Hive file doens't exist at the specified path"
            }
            try{
                New-PSDrive -PSProvider Registry -Name SRUM_Reg_Parse -Root HKEY_USERS | Out-Null
                reg load hku\srum $hive | out-null
            }
            catch{
                throw "Error: Can't mount Software Hive"
            }
        }

        $lookupLUID = @{
            1 = "IF_TYPE_OTHER"
            2 = "IF_TYPE_REGULAR_1822"
            3 = "IF_TYPE_HDH_1822"
            4 = "IF_TYPE_DDN_X25"
            5 = "IF_TYPE_RFC877_X25"
            6 = "IF_TYPE_ETHERNET_CSMACD"
            7 = "IF_TYPE_IS088023_CSMACD"
            8 = "IF_TYPE_ISO88024_TOKENBUS"
            9 = "IF_TYPE_ISO88025_TOKENRING"
            10 = "IF_TYPE_ISO88026_MAN"
            11 = "IF_TYPE_STARLAN"
            12 = "IF_TYPE_PROTEON_10MBIT"
            13 = "IF_TYPE_PROTEON_80MBIT"
            14 = "IF_TYPE_HYPERCHANNEL"
            15 = "IF_TYPE_FDDI"
            16 = "IF_TYPE_LAP_B"
            17 = "IF_TYPE_SDLC"
            18 = "IF_TYPE_DS1"
            19 = "IF_TYPE_E1"
            20 = "IF_TYPE_BASIC_ISDN"
            21 = "IF_TYPE_PRIMARY_ISDN"
            22 = "IF_TYPE_PROP_POINT2POINT_SERIAL"
            23 = "IF_TYPE_PPP"
            24 = "IF_TYPE_SOFTWARE_LOOPBACK"
            25 = "IF_TYPE_EON"
            26 = "IF_TYPE_ETHERNET_3MBIT"
            27 = "IF_TYPE_NSIP"
            28 = "IF_TYPE_SLIP"
            29 = "IF_TYPE_ULTRA"
            30 = "IF_TYPE_DS3"
            31 = "IF_TYPE_SIP"
            32 = "IF_TYPE_FRAMERELAY"
            33 = "IF_TYPE_RS232"
            34 = "IF_TYPE_PARA"
            35 = "IF_TYPE_ARCNET"
            36 = "IF_TYPE_ARCNET_PLUS"
            37 = "IF_TYPE_ATM"
            38 = "IF_TYPE_MIO_X25"
            39 = "IF_TYPE_SONET"
            40 = "IF_TYPE_X25_PLE"
            41 = "IF_TYPE_ISO88022_LLC"
            42 = "IF_TYPE_LOCALTALK"
            43 = "IF_TYPE_SMDS_DXI"
            44 = "IF_TYPE_FRAMERELAY_SERVICE"
            45 = "IF_TYPE_V35"
            46 = "IF_TYPE_HSSI"
            47 = "IF_TYPE_HIPPI"
            48 = "IF_TYPE_MODEM"
            49 = "IF_TYPE_AAL5"
            50 = "IF_TYPE_SONET_PATH"
            51 = "IF_TYPE_SONET_VT"
            52 = "IF_TYPE_SMDS_ICIP"
            53 = "IF_TYPE_PROP_VIRTUAL"
            54 = "IF_TYPE_PROP_MULTIPLEXOR"
            55 = "IF_TYPE_IEEE80212"
            56 = "IF_TYPE_FIBRECHANNEL"
            57 = "IF_TYPE_HIPPIINTERFACE"
            58 = "IF_TYPE_FRAMERELAY_INTERCONNECT"
            59 = "IF_TYPE_AFLANE_8023"
            60 = "IF_TYPE_AFLANE_8025"
            61 = "IF_TYPE_CCTEMUL"
            62 = "IF_TYPE_FASTETHER"
            63 = "IF_TYPE_ISDN"
            64 = "IF_TYPE_V11"
            65 = "IF_TYPE_V36"
            66 = "IF_TYPE_G703_64K"
            67 = "IF_TYPE_G703_2MB"
            68 = "IF_TYPE_QLLC"
            69 = "IF_TYPE_FASTETHER_FX"
            70 = "IF_TYPE_CHANNEL"
            71 = "IF_TYPE_IEEE80211"
            72 = "IF_TYPE_IBM370PARCHAN"
            73 = "IF_TYPE_ESCON"
            74 = "IF_TYPE_DLSW"
            75 = "IF_TYPE_ISDN_S"
            76 = "IF_TYPE_ISDN_U"
            77 = "IF_TYPE_LAP_D"
            78 = "IF_TYPE_IPSWITCH"
            79 = "IF_TYPE_RSRB"
            80 = "IF_TYPE_ATM_LOGICAL"
            81 = "IF_TYPE_DS0"
            82 = "IF_TYPE_DS0_BUNDLE"
            83 = "IF_TYPE_BSC"
            84 = "IF_TYPE_ASYNC"
            85 = "IF_TYPE_CNR"
            86 = "IF_TYPE_ISO88025R_DTR"
            87 = "IF_TYPE_EPLRS"
            88 = "IF_TYPE_ARAP"
            89 = "IF_TYPE_PROP_CNLS"
            90 = "IF_TYPE_HOSTPAD"
            91 = "IF_TYPE_TERMPAD"
            92 = "IF_TYPE_FRAMERELAY_MPI"
            93 = "IF_TYPE_X213"
            94 = "IF_TYPE_ADSL"
            95 = "IF_TYPE_RADSL"
            96 = "IF_TYPE_SDSL"
            97 = "IF_TYPE_VDSL"
            98 = "IF_TYPE_ISO88025_CRFPRINT"
            99 = "IF_TYPE_MYRINET"
            100 = "IF_TYPE_VOICE_EM"
            101 = "IF_TYPE_VOICE_FXO"
            102 = "IF_TYPE_VOICE_FXS"
            103 = "IF_TYPE_VOICE_ENCAP"
            104 = "IF_TYPE_VOICE_OVERIP"
            105 = "IF_TYPE_ATM_DXI"
            106 = "IF_TYPE_ATM_FUNI"
            107 = "IF_TYPE_ATM_IMA"
            108 = "IF_TYPE_PPPMULTILINKBUNDLE"
            109 = "IF_TYPE_IPOVER_CDLC"
            110 = "IF_TYPE_IPOVER_CLAW"
            111 = "IF_TYPE_STACKTOSTACK"
            112 = "IF_TYPE_VIRTUALIPADDRESS"
            113 = "IF_TYPE_MPC"
            114 = "IF_TYPE_IPOVER_ATM"
            115 = "IF_TYPE_ISO88025_FIBER"
            116 = "IF_TYPE_TDLC"
            117 = "IF_TYPE_GIGABITETHERNET"
            118 = "IF_TYPE_HDLC"
            119 = "IF_TYPE_LAP_F"
            120 = "IF_TYPE_V37"
            121 = "IF_TYPE_X25_MLP"
            122 = "IF_TYPE_X25_HUNTGROUP"
            123 = "IF_TYPE_TRANSPHDLC"
            124 = "IF_TYPE_INTERLEAVE"
            125 = "IF_TYPE_FAST"
            126 = "IF_TYPE_IP"
            127 = "IF_TYPE_DOCSCABLE_MACLAYER"
            128 = "IF_TYPE_DOCSCABLE_DOWNSTREAM"
            129 = "IF_TYPE_DOCSCABLE_UPSTREAM"
            130 = "IF_TYPE_A12MPPSWITCH"
            131 = "IF_TYPE_TUNNEL"
            132 = "IF_TYPE_COFFEE"
            133 = "IF_TYPE_CES"
            134 = "IF_TYPE_ATM_SUBINTERFACE"
            135 = "IF_TYPE_L2_VLAN"
            136 = "IF_TYPE_L3_IPVLAN"
            137 = "IF_TYPE_L3_IPXVLAN"
            138 = "IF_TYPE_DIGITALPOWERLINE"
            139 = "IF_TYPE_MEDIAMAILOVERIP"
            140 = "IF_TYPE_DTM"
            141 = "IF_TYPE_DCN"
            142 = "IF_TYPE_IPFORWARD"
            143 = "IF_TYPE_MSDSL"
            144 = "IF_TYPE_IEEE1394"
            145 = "IF_TYPE_RECEIVE_ONLY"
        }

        function profiles{
            $keys = (Get-ChildItem 'Srum_Reg_Parse:\srum\Microsoft\WlanSvc\Interfaces\*\profiles\' -Exclude metadata -Recurse).pspath
            $global:table = @{}
            foreach($key in $keys){
                $parsed = ''
                try{
                    $temp = [System.Text.Encoding]::ascii.GetString(((Get-ItemProperty ($key + '\metadata')).'channel hints'))
                    for($i = 0; $i -lt 100; $i++){
                        $temp = ($Temp.Split('?'))[0]
                        if($temp[$i] -match "[-a-zA-Z0-9]"){
                            $parsed += @($temp[$i])
                       }
                    }
                    $table[((Get-ItemProperty $key).profileindex)] = $parsed
                }
                catch{}
            }
        }

        function liveProfiles{
            $keys = (Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\WlanSvc\Interfaces\*\profiles\' -Exclude metadata -Recurse).pspath
            $global:table = @{}
            foreach($key in $keys){
                $parsed = ''
                try{
                    $temp = [System.Text.Encoding]::ascii.GetString(((Get-ItemProperty ($key + '\metadata')).'channel hints'))
                    for($i = 0; $i -lt 100; $i++){
                        $temp = ($Temp.Split('?'))[0]
                        if($temp[$i] -match "[-a-zA-Z0-9]"){
                            $parsed += @($temp[$i])
                       }
                    }
                    $table[((Get-ItemProperty $key).profileindex)] = $parsed
                }
                catch{}
            }
        }

        function replace-ssids{
            foreach($entry in $table.keys){
                foreach($temp in $out){
                    if($temp.l2profileid -eq $entry){
                        $temp.l2profileid = $table.item($entry)
                    }
                }   
            }
        }

        function sids-app-interface-time{
            foreach($item in $out){
                if($item.InterfaceLuid -notlike "if*"){
                    [int]$item2 = ([long]$item.interfaceluid) -shr 48
                    $item.interfaceluid = $lookupLUID.get_item($item2)
                }
                if($item.connectedtime -notlike "*m*"){
                    $ts =  [timespan]::fromseconds($item.ConnectedTime)
                    $item.ConnectedTime = "{0:hh'h' mm'm' ss's'}" -f ([datetime]$ts.Ticks)
                }
                $item.UserId = $hashSid.get_item([int]"$($item.UserId)")  

                $item.AppId = $hashApp.get_item([int]"$($item.appid)")  
            }
        }

        function sids-app-interface{
            foreach($item in $out){
                if($item.InterfaceLuid -notlike "if*"){
                    [int]$item2 = ([long]$item.interfaceluid) -shr 48
                    $item.interfaceluid = $lookupLUID.get_item($item2)
                }
                $item.UserId = $hashSid.get_item([int]"$($item.UserId)")  

                $item.AppId = $hashApp.get_item([int]"$($item.appid)")  
            }
        }

        function sids-app{
            foreach($item in $out){
                $item.UserId = $hashSid.get_item([int]"$($item.UserId)")  

                $item.AppId = $hashApp.get_item([int]"$($item.appid)")  
            }
        }

        Function Get-SRUMTableDataRows{
          Param(
              $Session,
              $JetTable,
              $BlobStrType=[System.Text.Encoding]::UTF16,
              $FutureTimeLimit = [System.TimeSpan]::FromDays(36500)
          )


        $DBRows = [System.Collections.ArrayList]@()
        Try{
            [Microsoft.Isam.Esent.Interop.ColumnInfo[]]$Columns = [Microsoft.Isam.Esent.Interop.Api]::GetTableColumns($Session, $JetTable.JetTableid)
            if ([Microsoft.Isam.Esent.Interop.Api]::TryMoveFirst($Session, $JetTable.JetTableid)){
                do{
                    $Row = New-Object PSObject 
                    foreach ($Column in $Columns){
                        switch ($Column.Coltyp){
                            ([Microsoft.Isam.Esent.Interop.JET_coltyp]::Bit) {
                                $Buffer = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsBoolean($Session, $JetTable.JetTableid, $Column.Columnid)
                                break
                            }
                            ([Microsoft.Isam.Esent.Interop.JET_coltyp]::DateTime) {
                                $Buffer = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsDateTime($Session, $JetTable.JetTableid, $Column.Columnid)
                                break
                            }
                            ([Microsoft.Isam.Esent.Interop.JET_coltyp]::IEEEDouble) {
                                $Buffer = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsDouble($Session, $JetTable.JetTableid, $Column.Columnid)
                                break
                            }
                            ([Microsoft.Isam.Esent.Interop.JET_coltyp]::IEEESingle) {
                                $Buffer = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsFloat($Session, $JetTable.JetTableid, $Column.Columnid)
                                break
                            }
                            ([Microsoft.Isam.Esent.Interop.JET_coltyp]::Long) {
                                $Buffer = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsInt32($Session, $JetTable.JetTableid, $Column.Columnid)
                                break
                            }
                            ([Microsoft.Isam.Esent.Interop.JET_coltyp]::Binary) {
                                if ( $BlobStrType -eq [System.Text.Encoding]::UTF16 ) {
                                    $Buffer = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString($Session, $JetTable.JetTableid, $Column.Columnid)
                                } else {
                                    $Buffer = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString($Session, $JetTable.JetTableid, $Column.Columnid, $BlobStrType)
                                }
                                break
                            }
                            ([Microsoft.Isam.Esent.Interop.JET_coltyp]::LongBinary) {
                                $Buffer = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumn($Session, $JetTable.JetTableid, $Column.Columnid)
                                break
                            }
                            ([Microsoft.Isam.Esent.Interop.JET_coltyp]::LongText) {
                                if ( $BlobStrType -eq [System.Text.Encoding]::UTF16 ) {
                                    $Buffer = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString($Session, $JetTable.JetTableid, $Column.Columnid)
                                } 
                                else {
                                    $Buffer = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString($Session, $JetTable.JetTableid, $Column.Columnid, $BlobStrType)
                                }
                                if (![System.String]::IsNullOrEmpty($Buffer)) {
                                    $Buffer = $Buffer.Replace("`0", "")
                                }
                                break
                            }
                            ([Microsoft.Isam.Esent.Interop.JET_coltyp]::Text) {
                                if ( $BlobStrType -eq [System.Text.Encoding]::UTF16 ) {
                                    $Buffer = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString($Session, $JetTable.JetTableid, $Column.Columnid)
                                } else {
                                    $Buffer = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString($Session, $JetTable.JetTableid, $Column.Columnid, $BlobStrType)
                                }
                                if (![System.String]::IsNullOrEmpty($Buffer)) {
                                    $Buffer = $Buffer.Replace("`0", "")
                                }
                                break
                            }
                            ([Microsoft.Isam.Esent.Interop.JET_coltyp]::Currency) {
                                $Buffer = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString($Session, $JetTable.JetTableid, $Column.Columnid, [System.Text.Encoding]::UTF8)
                                if (![System.String]::IsNullOrEmpty($Buffer)) {
                                    $Buffer = $Buffer.Replace("`0", "")
                                }
                                break
                            }
                            ([Microsoft.Isam.Esent.Interop.JET_coltyp]::Short) {
                                $Buffer = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsInt16($Session, $JetTable.JetTableid, $Column.Columnid)
                                break
                            }
                            ([Microsoft.Isam.Esent.Interop.JET_coltyp]::UnsignedByte) {
                                $Buffer = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsByte($Session, $JetTable.JetTableid, $Column.Columnid)
                                break
                            }
                            (14) {
                                $Buffer = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsInt32($Session, $JetTable.JetTableid, $Column.Columnid)
                                break
                            }
                            (15) {
                                try{
                                    $Buffer = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsInt64($Session, $JetTable.JetTableid, $Column.Columnid)
                                } 
                                catch{ 
                                    $Buffer = "Error"
                                }
                                if ($Buffer -Ne "Error" -and $column.name -eq "ConnectStartTime"){
                                    try {
                                        $DateTime = [System.DateTime]::FromBinary($Buffer)
                                        $DateTime = $DateTime.AddYears(1600)
                                        $buffer = $DateTime
                                        if ($DateTime -gt (Get-Date -Year 1970 -Month 1 -Day 1) -and $DateTime -lt ([System.DateTime]::UtcNow.Add($FutureTimeLimit))){
                                            $Buffer = $DateTime
                                        }
                                    }
                                    catch {}
                                }
                                break
                            }
                            default {
                                Write-Warning -Message "Did not match column type to $_"
                                $Buffer = [System.String]::Empty
                                break
                            }
                        }       
                        $Row | Add-Member -type NoteProperty -name $Column.Name -Value $Buffer 
                    }
                    [void]$DBRows.Add($row)
                } 
                while ([Microsoft.Isam.Esent.Interop.Api]::TryMoveNext($Session, $JetTable.JetTableid))      
            }
        }
        Catch{
            throw "Error: Could not read table"
            Break
        }
        return $DBRows
        }

        function map{
        $TableNameDBID="SruDbIdMapTable"
        [Microsoft.Isam.Esent.Interop.Table]$TableDBID = New-Object -TypeName Microsoft.Isam.Esent.Interop.Table($Session, $DatabaseId, $TableNameDBID, [Microsoft.Isam.Esent.Interop.OpenTableGrbit]::None)
        try{
            $NewTable = @{Name=$TableDBID.Name;Id=$TableDBID.JetTableid;Rows=@()}
            $DBRows = @()
            [Microsoft.Isam.Esent.Interop.ColumnInfo[]]$Columns = [Microsoft.Isam.Esent.Interop.Api]::GetTableColumns($Session, $TableDBID.JetTableid)
            $jettable = $Tabledbid
        }
        catch{
            throw "ERROR: Cannot access file, the file is locked or in use"
        }

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Retrieving SruIdDbMap Table..."
        $map = Get-SRUMTableDataRows -Session $Session -JetTable $TableDBId 
        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Translating SIDs and Applications from SruIdDbMap... This Could take up to 15 Minutes..."
        $global:hashSid = @{}
        $global:hashApp = @{}
        foreach($mData in $map){
            if($mData.idtype -eq 3){
                try{
                    $hex = $mData | Select-Object -ExpandProperty idblob
                    $hexString = ($hex|ForEach-Object ToString X2) -join ''   
                    $Bytes = [byte[]]::new($HexString.Length / 2)

                    For($i=0; $i -lt $HexString.Length; $i+=2){
                        $Bytes[$i/2] =[convert]::ToByte($HexString.Substring($i, 2), 16)
                    }
                    $idblobSid = (New-Object System.Security.Principal.SecurityIdentifier($Bytes,0)).Value
                    $hashSid.add($mData.idindex, $idblobSid)
                }
                catch{
                    $idblobSid = "Unable to Retrieve"
                    $hashSid.add($mData.idindex, $idblobSid)
                }
            }
            else{
                try{
                    $bytes = $mData | Select-Object -ExpandProperty idblob
                    $idblobApp = [System.Text.Encoding]::unicode.GetString($bytes)
                    $hashApp.add($mData.idindex, $idblobApp)
                    }
                catch{
                    $idblobApp = "Unable to Retrieve"
                    $hashApp.add($mData.idindex, $idblobApp)
                }
            }
        }

        }

        function networkConnectivity{
        $tab = "{DD6636C4-8929-4683-974E-22C046A43763}"
        [Microsoft.Isam.Esent.Interop.Table]$Tab2 = New-Object -TypeName Microsoft.Isam.Esent.Interop.Table($Session, $DatabaseId, $Tab, [Microsoft.Isam.Esent.Interop.OpenTableGrbit]::None)

        $NewTable = @{Name=$TableDBID.Name;Id=$TableDBID.JetTableid;Rows=@()}
        $DBRows = @()
        [Microsoft.Isam.Esent.Interop.ColumnInfo[]]$Columns = [Microsoft.Isam.Esent.Interop.Api]::GetTableColumns($Session, $Tab2.JetTableid)
        $jettable = $tab2

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Retrieving Network Connectivity Table..."
        $global:out = Get-SRUMTableDataRows -Session $Session -JetTable $Tab2

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Network Connectivity: Normalizing Wireless Profile Data..."
        if($Live){
            liveProfiles
        }
        else{
            Profiles
        }
        replace-ssids

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Network Connectivity: Normalizing User SIDs, Connected Time, Interface LUIDs, and Applications..."
        sids-app-interface-time

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Exporting Network Connectivity Table..."

        $CompiledResults.add('InvokeSRUMDumpNetworkConnectivity',$(
            $out | Select-Object @{Name='SRUM Entry ID'; Expression='AutoIncID'}, @{Name='SRUM Entry Creation'; Expression='Timestamp'}, @{Name='Application'; Expression='Appid'}, @{Name='User SID'; Expression='UserID'}, @{Name='Interface'; Expression='InterfaceLUID'}, @{Name='Profile'; Expression='L2ProfileID'}, @{Name='Connected Time'; Expression='ConnectedTime'}, @{Name='Connect Start Time (UTC)'; Expression='ConnectStartTime'}, @{Name='Profile Flags'; Expression='L2ProfileFlags'}
        ))
        }

        function networkData{
        $tab = "{973F5D5C-1D90-4944-BE8E-24B94231A174}"
        [Microsoft.Isam.Esent.Interop.Table]$Tab3 = New-Object -TypeName Microsoft.Isam.Esent.Interop.Table($Session, $DatabaseId, $Tab, [Microsoft.Isam.Esent.Interop.OpenTableGrbit]::None)

        $NewTable = @{Name=$TableDBID.Name;Id=$TableDBID.JetTableid;Rows=@()}
        $DBRows = @()
        [Microsoft.Isam.Esent.Interop.ColumnInfo[]]$Columns = [Microsoft.Isam.Esent.Interop.Api]::GetTableColumns($Session, $Tab3.JetTableid)
        $jettable = $tab3

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Retrieving Network Data Usage Table... This Could take up to 15 Minutes..."
        $global:out = Get-SRUMTableDataRows -Session $Session -JetTable $Tab3

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Network Data Usage: Normalizing Wireless Profile Data..."
        if($Live){
            liveProfiles
        }
        else{
            Profiles
        }
        replace-ssids

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Network Data Usage: Normalizing User SIDs, Interface LUIDs, and Applications..." 
        sids-app-interface

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Exporting Network Data Usage Table..."

        $CompiledResults.add('InvokeSRUMDumpNetworkDataUsage',$(
            $out | Select-Object @{Name='SRUM Entry ID'; Expression='AutoIncID'}, @{Name='SRUM Entry Creation'; Expression='Timestamp'}, @{Name='Application'; Expression='Appid'}, @{Name='User SID'; Expression='UserID'}, @{Name='Interface'; Expression='InterfaceLUID'}, @{Name='Profile'; Expression='L2ProfileID'}, @{Name='Profile Flags'; Expression='L2ProfileFlags'}, @{Name='Bytes Sent'; Expression='bytessent'}, @{Name='Bytes Received'; Expression='bytesrecvd'}
        ))
        }

        function applicationUse{
        $tab = "{D10CA2FE-6FCF-4F6D-848E-B2E99266FA89}"
        [Microsoft.Isam.Esent.Interop.Table]$Tab4 = New-Object -TypeName Microsoft.Isam.Esent.Interop.Table($Session, $DatabaseId, $Tab, [Microsoft.Isam.Esent.Interop.OpenTableGrbit]::None)

        $NewTable = @{Name=$TableDBID.Name;Id=$TableDBID.JetTableid;Rows=@()}
        $DBRows = @()
        [Microsoft.Isam.Esent.Interop.ColumnInfo[]]$Columns = [Microsoft.Isam.Esent.Interop.Api]::GetTableColumns($Session, $Tab4.JetTableid)
        $jettable = $tab4

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Retrieving Application Usage Table..."
        $global:out = Get-SRUMTableDataRows -Session $Session -JetTable $Tab4

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Application Usage: Normalizing User SIDs and Applications..."
        sids-app

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Exporting Application Usage Table..."
        $CompiledResults.add('InvokeSRUMDumpApplicationUsage',$(
            $out | Select-Object @{Name='SRUM Entry ID'; Expression='AutoIncID'}, @{Name='SRUM Entry Creation'; Expression='Timestamp'}, @{Name='Application'; Expression='Appid'}, @{Name='User SID'; Expression='UserID'}, BackgroundBytesRead, BackgroundBytesWritten, BackgroundContextSwitches, BackgroundCycleTime, BackgroundNumberOfFlushes, BackgroundNumReadOperations, BackgroundNumWriteOperations, FaceTime, ForegroundBytesRead, ForegroundBytesWritten, ForegroundContextSwitches, ForegroundCycleTime, ForegroundNumberOfFlushes, ForegroundNumReadOperations, ForegroundNumWriteOperations
        ))
        }

        function applicationTimeline{
        $tab = "{5C8CF1C7-7257-4F13-B223-970EF5939312}"
        [Microsoft.Isam.Esent.Interop.Table]$Tab5 = New-Object -TypeName Microsoft.Isam.Esent.Interop.Table($Session, $DatabaseId, $Tab, [Microsoft.Isam.Esent.Interop.OpenTableGrbit]::None)

        $NewTable = @{Name=$TableDBID.Name;Id=$TableDBID.JetTableid;Rows=@()}
        $DBRows = @()
        [Microsoft.Isam.Esent.Interop.ColumnInfo[]]$Columns = [Microsoft.Isam.Esent.Interop.Api]::GetTableColumns($Session, $Tab5.JetTableid)
        $jettable = $tab5

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Retrieving Application Timeline Table..."
        $global:out = Get-SRUMTableDataRows -Session $Session -JetTable $Tab5

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Application Timeline: Normalizing User SIDs and Applications..."
        sids-app

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Exporting Application Timeline Table to $exportDir\ApplicationTimeline..."
        $CompiledResults.add('InvokeSRUMDumpApplicationUsage',$(
            $out | Select-Object @{Name='SRUM Entry ID'; Expression='AutoIncID'}, @{Name='SRUM Entry Creation'; Expression='Timestamp'}, @{Name='Application'; Expression='Appid'}, @{Name='User SID'; Expression='UserID'}, BinaryData, EndTime, DurationMS, SpanMS, TimelineEnd, InFocusTimeline, UserInputTimeline, CompRenderedTimeline, CompDirtiedTimeline, CompPropagatedTimeline, AudioInTimeline, AudioTimeline, CPUTimeline, DiskTimeline, NetworkTimeline, MBBTimline, InFocusS, PSMForegroundS, UserInputS, CompRenderedS, CompDiriedS, CompPropagatedS, AudioS, AudioOutS, Cycles, CyclesBreakdown, CyclesWOB, CyclesWOBBreakdown, DiskRaw, NetworkTailRaw, NetworkBytesRaw, MBBTailRaw, DisplayRequiredS, DisplayRequiredTimeline, KeyboardInputTimeline, KeyboardInputS, MouseInputS
        ))
        }

        function pushNotifications{
        $tab = "{D10CA2FE-6FCF-4F6D-848E-B2E99266FA86}"
        [Microsoft.Isam.Esent.Interop.Table]$Tab6 = New-Object -TypeName Microsoft.Isam.Esent.Interop.Table($Session, $DatabaseId, $Tab, [Microsoft.Isam.Esent.Interop.OpenTableGrbit]::None)

        $NewTable = @{Name=$TableDBID.Name;Id=$TableDBID.JetTableid;Rows=@()}
        $DBRows = @()
        [Microsoft.Isam.Esent.Interop.ColumnInfo[]]$Columns = [Microsoft.Isam.Esent.Interop.Api]::GetTableColumns($Session, $Tab6.JetTableid)
        $jettable = $tab6

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Retrieving Push Notifications Table..."
        $out = Get-SRUMTableDataRows -Session $Session -JetTable $Tab6

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Push Notifications: Normalizing User SIDs and Applications..."
        sids-app

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Exporting Push Notifications Table..."
        $CompiledResults.add('InvokeSRUMDumpPushNotifications',$(
            $out | Select-Object @{Name='SRUM Entry ID'; Expression='AutoIncID'}, @{Name='SRUM Entry Creation'; Expression='Timestamp'}, @{Name='Application'; Expression='Appid'}, @{Name='User SID'; Expression='UserID'}, NotificationType, PayloadSize, NetworkType
        ))
        }

        $EsentDllPath = "$env:SYSTEMROOT\Microsoft.NET\assembly\GAC_MSIL\microsoft.isam.esent.interop\v4.0_10.0.0.0__31bf3856ad364e35\Microsoft.Isam.Esent.Interop.dll"
        Add-Type -Path $EsentDllPath

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Connecting to the Database..."
        [System.Int32]$FileType = -1
        [System.Int32]$PageSize = -1
        [Microsoft.Isam.Esent.Interop.Api]::JetGetDatabaseFileInfo($Path, [ref]$PageSize, [Microsoft.Isam.Esent.Interop.JET_DbInfo]::PageSize)
        [Microsoft.Isam.Esent.Interop.Api]::JetGetDatabaseFileInfo($Path, [ref]$FileType, [Microsoft.Isam.Esent.Interop.JET_DbInfo]::FileType)
        [Microsoft.Isam.Esent.Interop.JET_filetype]$DBType = [Microsoft.Isam.Esent.Interop.JET_filetype]($FileType)

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Opening a JET Session..."
        [Microsoft.Isam.Esent.Interop.JET_INSTANCE]$Instance = New-Object -TypeName Microsoft.Isam.Esent.Interop.JET_INSTANCE
        [Microsoft.Isam.Esent.Interop.JET_SESID]$Session = New-Object -TypeName Microsoft.Isam.Esent.Interop.JET_SESID
        $Temp = [Microsoft.Isam.Esent.Interop.Api]::JetSetSystemParameter($Instance, [Microsoft.Isam.Esent.Interop.JET_SESID]::Nil, [Microsoft.Isam.Esent.Interop.JET_param]::DatabasePageSize, $PageSize, $null)
        $Temp = [Microsoft.Isam.Esent.Interop.Api]::JetSetSystemParameter($Instance, [Microsoft.Isam.Esent.Interop.JET_SESID]::Nil, [Microsoft.Isam.Esent.Interop.JET_param]::Recovery, [int]$Recovery, $null)
        $Temp = [Microsoft.Isam.Esent.Interop.Api]::JetSetSystemParameter($Instance, [Microsoft.Isam.Esent.Interop.JET_SESID]::Nil, [Microsoft.Isam.Esent.Interop.JET_param]::CircularLog, [int]$CircularLogging, $null)
        [Microsoft.Isam.Esent.Interop.Api]::JetCreateInstance2([ref]$Instance, "Instance", "Instance", [Microsoft.Isam.Esent.Interop.CreateInstanceGrbit]::None)
        $Temp = [Microsoft.Isam.Esent.Interop.Api]::JetInit2([ref]$Instance, [Microsoft.Isam.Esent.Interop.InitGrbit]::None)
        [Microsoft.Isam.Esent.Interop.Api]::JetBeginSession($Instance, [ref]$Session, $UserName, $Password)

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Opening the Database..."
        [Microsoft.Isam.Esent.Interop.JET_DBID]$DatabaseId = New-Object -TypeName Microsoft.Isam.Esent.Interop.JET_DBID
        $Temp = [Microsoft.Isam.Esent.Interop.Api]::JetAttachDatabase($Session, $Path, [Microsoft.Isam.Esent.Interop.AttachDatabaseGrbit]::ReadOnly)
        $Temp = [Microsoft.Isam.Esent.Interop.Api]::JetOpenDatabase($Session, $Path, $Connect, [ref]$DatabaseId, [Microsoft.Isam.Esent.Interop.OpenDatabaseGrbit]::ReadOnly)

        map
        networkConnectivity
        networkData
        applicationUse
        applicationTimeline
        pushNotifications

        [gc]::collect()
        if($offline){
            remove-psdrive -Name SRUM_Reg_Parse
            reg unload hku\srum | Out-Null
        }

        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Gracefully shutting down the Connection to the Database..."
        Write-Verbose -Message "Shutting down database $Path due to normal close operation."
        [Microsoft.Isam.Esent.Interop.Api]::JetCloseDatabase($Session, $DatabaseId, [Microsoft.Isam.Esent.Interop.CloseDatabaseGrbit]::None)
        [Microsoft.Isam.Esent.Interop.Api]::JetDetachDatabase($Session, $Path)
        [Microsoft.Isam.Esent.Interop.Api]::JetEndSession($Session, [Microsoft.Isam.Esent.Interop.EndSessionGrbit]::None)
        [Microsoft.Isam.Esent.Interop.Api]::JetTerm($Instance)
        write-host -ForegroundColor Yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Shutdown Completed Successfully"
    }
    Invoke-SRUMDump -live

#########################
### Restore Points
#########################

    $CompiledResults.add('GetComputerRestorePoint',$(
        Get-ComputerRestorePoint
    ))

#########################
### Prefetch
#########################

    # GRAB FIRST AS THIS IS VERY VOLITILE
    # number of time an application has been executed,
    # The original path of execution,
    # the last time of execution
        # Note: Up to last 8 times application executed is stored in prefetch file. If I also add the timestamp of the prefetch file creation - we will have 9 run times of the application.
    # When a malicious file was executed?
    # Where it was launched from?
    # How many times it has been run?
    # What DLLs were used by the malicious code?
    # Name and location of the malicious file (even if deleted)?

    #####################
    #####################
    $CompiledResults.add('PrefetchFiles',$(
        Get-ChildItem C:\Windows\Prefetch -Force
    ))

#########################
### Virtualization
#########################

    #####################
    #####################
    $CompiledResults.add('DetectVMWareHosts',$(
        $VMwareDetected   = $False
        $VMNetworkAdapter = $(Get-WmiObject Win32_NetworkAdapter -Filter 'Manufacturer LIKE "%VMware%" OR Name LIKE "%VMware%"')
        $VMBios           = $(Get-WmiObject Win32_BIOS -Filter 'SerialNumber LIKE "%VMware%"')
        $VMWareService    = $(Get-Service | Where-Object {$_.Name -match "vmware" -and $_.Status -eq 'Running'} | Select-Object -ExpandProperty Name)
        $VMWareProcess    = $(Get-Process | Where-Object Name -match "vmware" | Select-Object -ExpandProperty Name)
        $VMToolsProcess   = $(Get-Process | Where-Object Name -match "vmtoolsd" | Select-Object -ExpandProperty Name)
        if($VMNetworkAdapter -or $VMBios -or $VMToolsProcess) {
            $VMwareDetected = $True
        }
        [PSCustomObject]@{
            PSComputerName   = $env:COMPUTERNAME
            Name             = 'VMWare Detection'
            VMWareDetected   = $VMwareDetected
            VMNetworkAdapter = $VMNetworkAdapter
            VMBIOS           = $VMBIOS
            VMWareService    = $VMWareService
            VMWareProcess    = $VMWareProcess
            VMToolsProcess   = $VMToolsProcess
        }    
    ))

    #####################
    #####################
    $CompiledResults.add('GetVM',$(
        Get-VM -VMName * | Select-Object -Property * 
    ))

    #####################
    #####################
    $CompiledResults.add('',$(
        Get-VMNetworkAdapter -VMName * | Select-Object -Property *
    ))

    #####################
    #####################
    $CompiledResults.add('GetVMSnapshot',$(
        Get-VMSnapshot -VMName *
    ))

    return $CompiledResults
}


$CompiledResults = Get-EndpointData