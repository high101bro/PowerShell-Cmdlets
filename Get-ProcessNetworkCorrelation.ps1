#$ErrorActionPreference="SilentlyContinue"

# Create Hashtable of all network processes and their PIDs
$Connections = @{}
foreach($Connection in Get-NetTCPConnection) {
    $connStr = "[$($Connection.State)] " + "$($Connection.LocalAddress)" + ":" + "$($Connection.LocalPort)" + " <--> " + "$($Connection.RemoteAddress)" + ":" + "$($Connection.RemotePort)`n"
    if($Connection.OwningProcess -in $Connections.keys) {
        if($connStr -notin $Connections[$Connection.OwningProcess]) {
            $Connections[$Connection.OwningProcess] += $connStr
        }
    }
    else{
        $Connections[$Connection.OwningProcess] = $connStr
    }
}
$ProcessesWMI       = Get-WmiObject -Class Win32_Process 
$ProcessesPS        = Get-Process
$NetworkConnections = Get-NetTCPConnection

$ProcessCount   = ($ProcessesWMI).count
$IterationCount = 0
foreach ($Process in $ProcessesWMI) {
    $IterationCount += 1
    $ProcessesPsId = $ProcessesPS | Where Id -eq $Process.ProcessId
    Write-Progress -Activity "Compiling Process Info and TCP Network Connections" -Status "Progress: $($Process.Name)" -PercentComplete ($IterationCount/$ProcessCount*100)
    $Process | Add-Member -NotePropertyName NetworkConnections -NotePropertyValue $Connections[$Process.ProcessId] -ErrorAction SilentlyContinue
    $Process | Add-Member -NotePropertyName ParentProcessName  -NotePropertyValue $((Get-Process -Id ($Process.ParentProcessId) -ErrorAction SilentlyContinue).name)
    $Process | Add-Member -NotePropertyName FileHash           -NotePropertyValue "MD5: $((Get-FileHash -Path ($Process.Path) -Algorithm MD5 -ErrorAction SilentlyContinue).Hash)"
    $Process | Add-Member -NotePropertyName DateCreated        -NotePropertyValue "$([Management.ManagementDateTimeConverter]::ToDateTime($Process.CreationDate))" -ErrorAction SilentlyContinue
    $Process | Add-Member -NotePropertyName Duration           -NotePropertyValue "$((New-TimeSpan -Start ($Process.DateCreated)).ToString())" -ErrorAction SilentlyContinue

    $Process | Add-Member -NotePropertyName Handle        -NotePropertyValue "$($ProcessesPsId.Handle)"
    $Process | Add-Member -NotePropertyName HandleCount   -NotePropertyValue "$($ProcessesPsId.HandleCount)"
    $Process | Add-Member -NotePropertyName Product       -NotePropertyValue "$($ProcessesPsId.Product)"
    $Process | Add-Member -NotePropertyName PSDescription -NotePropertyValue "$($ProcessesPsId.Description)"
    $Process | Add-Member -NotePropertyName Threads       -NotePropertyValue "$($ProcessesPsId.Threads.Id)"
    $Process | Add-Member -NotePropertyName Modules       -NotePropertyValue "$($ProcessesPsId.Modules.ModuleName)"

    $AuthenticodeSignature = Get-AuthenticodeSignature $Process.Path
    $Process | Add-Member -NotePropertyName StatusMessage     -NotePropertyValue $( if ($AuthenticodeSignature.StatusMessage -match 'verified') {'Signature Verified'}; elseif ($AuthenticodeSignature.StatusMessage -match 'not digitally signed') {'The file is not digitially signed.'}) -Force -ErrorAction SilentlyContinue
    $Process | Add-Member -NotePropertyName SignerCertificate -NotePropertyValue $($AuthenticodeSignature.SignerCertificate.Thumbprint) -Force -ErrorAction SilentlyContinue
    $Process | Add-Member -NotePropertyName Company           -NotePropertyValue $($AuthenticodeSignature.SignerCertificate.Subject.split(',')[0] -replace 'CN=' -replace '"') -Force -ErrorAction SilentlyContinue
    #$Process | Add-Member -NotePropertyName RSAKey            -NotePropertyValue $($AuthenticodeSignature.SignerCertificate.PublicKey.EncodedKeyValue.rawdata -join '') -Force -ErrorAction SilentlyContinue

    $Owner    = $Process.GetOwner().Domain.ToString() + "\"+ $Process.GetOwner().User.ToString()
    $OwnerSID = $Process.GetOwnerSid().Sid.ToString()
    $Process | Add-Member -NotePropertyName Owner    -NotePropertyValue $Owner
    $Process | Add-Member -NotePropertyName OwnerSID -NotePropertyValue $OwnerSID
}
$ProcessesWMI | Select-Object -Property PSComputerName, Name, ProcessId, ParentProcessId, ParentProcessName, DateCreated, Duration, @{Name="NetworkConnections";Expression={$_.NetworkConnections -replace "`r`n","`r"}}, CommandLine, FileHash, SignerCertificate, StatusMessage, Company, Product, PSDescription, Owner, OwnerSID, Path, @{Name="Memory KB";Expression={"$([Math]::Round($($_WorkingSetSize / 1024),2))"}}, HandleCount, Handle, ThreadCount, Threads, Modules `
    | Out-GridView -Title 'Enhanced Process & Network Connection Correlation' -PassThru <#`
    | ForEach-Object {
        $_.ProcessId `
        | Stop-Process -Force -Confirm
    }
    #>