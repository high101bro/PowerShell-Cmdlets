param(
    [Parameter(
        Position=0, 
        Mandatory=$true, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true
    )]
    [Alias('PSComputerName','MachineName')]
    [string[]]$ComputerName,

    [Parameter(
        Position=1, 
        Mandatory=$false
    )]
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty    
)

if ($Credential) {
    Invoke-Command -ScriptBlock {
        Get-Process | Select-Object @{Name='PSComputerName';Expression={$(hostname)}}, *
    } -ComputerName $ComputerName -Credential $Credential `
    | Select-Object -Property PSComputerName, * -ErrorAction SilentlyContinue `
    | Sort-Object -Property Name, PSComputername, * -ErrorAction SilentlyContinue `
    | Out-GridView -Title 'Processes To Stop' -PassThru -OutVariable ProcessesToStop
}
else {
    Invoke-Command -ScriptBlock {
        Get-Process | Select-Object @{Name='PSComputerName';Expression={$(hostname)}}, *        
    } -ComputerName $ComputerName `
    | Select-Object -Property PSComputerName, * -ErrorAction SilentlyContinue `
    | Sort-Object -Property Name, PSComputername, * -ErrorAction SilentlyContinue `
    | Out-GridView -Title 'Processes To Stop' -PassThru -OutVariable ProcessesToStop
}

$ProcessesToStop = $ProcessesToStop | Sort-Object -Property PSComputerName
$Computers = $ProcessesToStop | Select-Object -ExpandProperty PSComputerName -Unique | Sort-Object

foreach ($Computer in $Computers) {    
    $Session = $null

    try {
        if ($Credential) {
            $Session = New-PSSession -ComputerName $Computer -Credential $Credential
        }
        else {
            $Session = New-PSSession -ComputerName $Computer
        }
        Write-Host "Connected to:  $Computer" -ForegroundColor Cyan

        if ($Session) {
            foreach ($Process in $ProcessesToStop){
                if ($Process.PSComputerName -eq $Computer){
                    $Process = $Process.Name
                    Write-Host "  - Stopping:  $Process" -ForegroundColor Green
                    Invoke-Command -ScriptBlock { param($Process); Stop-Process -Name $Process } -ArgumentList $Process -Session $Session                    
                }
            }
            Remove-PSSession -Session $Session
        }
    }
    catch {
        Write-Host "Unable to Connect:  $Computer" -ForegroundColor Red
    }
}



