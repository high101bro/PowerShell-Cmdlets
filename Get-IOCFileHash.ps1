<#
.Example
    AF1787F1DBE0053D74FC687E7233F8CE 
    3DF3B76B19DA92A8ADC01FF38560282D
#>

[CmdletBinding(DefaultParameterSetName = 'Set 1')]
param(
    [Parameter(
        Position = 0, 
        Mandatory = $false,
        ParameterSetName = 'Set 1'
        )]
            [string[]]$ComputerName = 'localhost',
    [Parameter(
        Position = 1, 
        Mandatory = $true,
        ParameterSetName = 'Set 1'
        )]
            [string[]]$Hashes,
    [Parameter(
        Position = 2, 
        Mandatory = $true,
        ParameterSetName = 'Set 1'
        )]
            [string[]]$Directory
)
$Folder = Get-ChildItem -Path $Directory | Select-Object -Property FullName

Foreach ($Computer in $ComputerName) {
    Invoke-Command -ComputerName $Computer -ScriptBlock {
        param ($Hashes,$Folder,$Computer)
        $Match = [Ordered]@{}
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



