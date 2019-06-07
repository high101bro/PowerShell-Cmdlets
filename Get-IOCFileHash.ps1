<#
.Synopsis
    Searches multiple remote computers for MD5 file hashes in multiple directories.

.Description
    The cmdlet all allows you to query multiple remote computers to search if any of them have an MD5 file hash that matches one more files file hashes you provide.

.Parameter ComputerName
    Enter one or more ComputerNames to query for connections.

.Parameter Directory
    Enter one or more Directories to hash files and search search for a match.

.Parameter Hash
    Enter one or more MD5 hashes to match upon.

.Example
    The following command queries two computers for two MD5 file hash.

    .\Get-IOCFileHash.ps1 -ComputerName Computer1,Computer2 -Directory C:\Users\<username>\Downloads -Hash 'AF1787F1DBE0053D74FC687E7233F8CE','3DF3B76B19DA92A8ADC01FF38560282D'

.Example
    The following command queries the localhost for file hashes contained within a file, search in the default directory c:\Windows\System32.

    .\Get-IOCNetworkConnection.ps1 -Hash (Get-Content .\hashes.txt)

.Example
    The following command queries multiple computers for multiple remote IPs and multiple remote ports.

    .\Get-IOCFileHash.ps1 -ComputerName Computer1,Computer2,Computer3 -IP '192.168.138.170','52.33.41.59' -Port (Get-Content .\PortsList.txt)
#>

param(
    [Parameter(
        Position = 0, 
        Mandatory = $false
        )]
            [string[]]$ComputerName = 'localhost',
    [Parameter(
        Position = 1, 
        Mandatory = $true
        )]
            [string[]]$Hashes,
    [Parameter(
        Position = 2, 
        Mandatory = $true
        )]
            [string[]]$Directory
)
$Folder = Get-ChildItem -Path $Directory | Select-Object -Property FullName

Foreach ($Computer in $ComputerName) {
    Invoke-Command -ComputerName $Computer -ScriptBlock {
        param ($Hashes,$Folder,$Computer)
        #$Match = [Ordered]@{}
        Foreach ($Item in $Folder){
            $FileHash = (Get-FileHash -Algorithm MD5 -Path $Item.FullName).Hash
            
            if ($FileHash -in $Hashes) {
                Write-Host "FileHash Found: " -NoNewline -ForegroundColor Red
                Write-Host "$($FileHash) " -NoNewline -ForegroundColor cyan
                Write-Host "$($Item.Fullname)" -ForegroundColor Yellow
                #"Filehash Found: {0} {1}" -f $Hash,$($Item.FullName)
                #$Match += @{ $($Hash) = "$($Item.Fullname)" }
            }            
        }
        #return [PSCustomObject]$match
    } -ArgumentList @($Hashes,$Folder,$Computer)
}
