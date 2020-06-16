param(
    [Parameter(
        Position = 0, 
        Mandatory = $true
    )]
    [Alias('Script','Command','Code')]
    $ScriptBlock,

    [Parameter(
        Position = 1, 
        Mandatory = $false
    )]
    [Alias('RefreshRate','RefreshRateInSeconds')]
    [int]$Refresh = 1,

    [Parameter(
        Position = 2, 
        Mandatory = $false
    )]
    [Alias('Duration','DurationInSeconds')]
    [int]$Timer = 1000000000, #like foreaver... a billion seconds

    [Parameter(Mandatory = $false)]
    [switch]$NoHeader
)
$Seconds = 0
While ($Seconds -lt $Timer) {
    # clears the terminal screen
    Clear-Host

    if (-not $NoHeader) {
        # Displays the command that was executed at the top of the screen
        Write-Host ''
        Write-Host "Command to Watch:   " -ForeGroundColor Red -NoNewline
        Write-Host "$($ScriptBlock)" -ForeGroundColor White
        Write-Host ''
        
        # Measures how long the command took to excute time
        $measure = measure-command {& $ScriptBlock}

        Write-Host "The following are displayed in seconds:" -ForeGroundColor Cyan

        # Displays the exection time
        Write-Host "   Exeuction Time:  $($Measure.TotalSeconds)" -ForeGroundColor Yellow

        # Duration in seconds
        Write-Host "   Timer Duration:  $($Seconds)/$($Timer)" -ForeGroundColor Yellow

        # Displays the exection time
        Write-Host "   Refresh Rate:    $($Refresh)" -ForeGroundColor Yellow
    }

    # Format-Table includes the header once the screen is cleared
    $results = & $ScriptBlock | Format-Table 

    # Results are displayed to the screen
    $results
    
    $Seconds += $Refresh
    Start-Sleep -Seconds $Refresh
}
