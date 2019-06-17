  
<#
.SYNOPSIS
    This script checks for Alternate Data Streams (ADS) on remote computers and provides you information about their contents.

.DESCRIPTION
    This script check for Alternate Data Streams on the local or remote comptuers. It allows for easy discovery of stream names and stream, as well as supports multiple directories searches, directory recursion, ADS extraction, and the exclusion of Zone.Identifiers streams.
    
    Version        : v1.0
    Author         : high101bro
    Email          : high101bro@gmail.com
    Website        : https://github.com/high101bro
    Created        : 7 June 2019

.EXAMPLE
    The following example is the default execution of the script. It searches through the present working directory on the localhost for all streams other than :DATA.
    .\Get-AlternateDataStream.ps1

.EXAMPLE
    The following example searches for all alternate data streams, except for the Zone.Identifier, in multiple directories on the localhost.
    .\Get-AlternateDataStream.ps1 --Directory $env:userprofile\Downloads,$env:userprofile\Desktop -ExcludeZoneIdentifier

.EXAMPLE
    The following examples searches for all alternate data streams in directories imported from a file. The alaternate data streams are extracted and saved to file.
    .\Get-AlternateDataStream.ps1 -Directory (Get-Content .\directories.txt) -ExtractADStoFile

.EXAMPLE
    The following example recursively searches for alternate data streams in the provided directory throughout multiple computers.
    .\Get-AlternateDataStream.ps1 -ComputerName localhost,dellwin10 -Directory $env:userprofile -Recurse

.PARAMETER ComputerName
    This parameter allows you to enter one or more remote computers.

.PARAMETER Directory
    This parameter allows you to enter one ore more directories.

.PARAMETER ExcludeZoneIdentifier
    This parameter switch allows you to exclude files with Zone Identifiers data streams.
    
    The Zone Identifiers are:
        ZoneID 0 - Local Machine Zone
                   The most trusted zone for content that exists on the local computer.
        ZoneID 1 - Local Intranet Zone
                   For content located on an organization’s intranet.
        ZoneID 2 - Trusted Sites Zone
                   For content located on Web sites that are considered more reputable or trustworthy than other sites on the Internet.
        ZoneID 3 - Internet Zone
                   For Web sites on the Internet that do not belong to another zone.
        ZoneID 4 - Restricted Sites Zone
                   For Web sites that contain potentially-unsafe content.

.PARAMETER Recurse
    This parameter switch allows you to recursively search for alternate data streams in the directories provided.

.PARAMETER ExtractADStoFile
    This parameter switch extracts the alternate data stream's content and save it as a .txt file. Extracted files are saved to the user's Downloads directory at "$env:USERPROFILE\Downloads\Alternate Data Stream Files". The default extension of .txt is a bit of a minor safety measure against would be malware. This enables you to easily read most data, but the file extension may need to be change depending on what is in the ADS. For example if the ADS contained an executable, rename the file extension from .txt to .exe to have it be recognized appropriately.

.NOTES    
    ###########################
    #  PowerShell Script ADS  #
    ###########################
    
    # Create an ADS that contains a Powershell script
        New-Item -ItemType File -path "$env:userprofile\desktop\ADS_File_with_PowerShell_Script.txt" -value "This file Contains an embedded PowerShell script within an Alternate Data Stream.`r`nTwo notepad.exe windows should appear." -force
        Add-Content -path "$env:userprofile\desktop\ADS_File_with_PowerShell_Script.txt" -stream PowerShellScript -value '$x=0; while ($x -lt 2) {Start-Process notepad.exe "$env:userprofile\desktop\ADS_File_with_PowerShell_Script.txt"; $x++}'

    # Execute the ADS content
        powershell.exe -command $(Get-Content "$env:userprofile\desktop\ADS_File_with_PowerShell_Script.txt" -stream 'PowerShellScript')
    

    ############################
    #  Executable Program ADS  #
    ############################

    # Create an ADS that contains an executable file
        New-Item -ItemType File -Path "$env:userprofile\desktop\ADS File with CMD Executable.txt" -value "This file Contains an embedded executeion file within an Alternate Data Stream.`r`nA cmd.exe terminal should appear." -force
        Add-Content -Path "$env:userprofile\desktop\ADS File with CMD Executable.txt:cmd.exe" -stream cmd.exe -value $(Get-Content -path c:\windows\system32\cmd.exe -Raw)

    # Execute the ADS content
        Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine = "$env:userprofile\desktop\ADS File with CMD Executable.txt:cmd.exe"}


    ####################
    #  Basic Text ADS  #
    ####################

    # Create an ADS that contains basic text
        New-Item -ItemType File -Path "$env:userprofile\Downloads\ADS_Test.txt" -Value 'This file has an embedded Alternate Data Stream that contains basic text.' -Force
        Set-Content -Path "$env:userprofile\Downloads\ADS_Test.txt:SecretText" -Stream SecretText -Value "This is some super secret text as an Alternate Data Stream!!!" 

    # Discover ADS and Read Data Stream
        Get-Item -Path "$env:userprofile\Downloads\ADS_Test.txt" -Stream * | Where-Object {$_.stream -ne ':$Data'} | Select-OBject -Property Filename, Stream
        Get-Content -Path "$env:userprofile\Downloads\ADS_Test.txt" -Stream "SecretText" -Raw

.INPUTS
    None

.OUTPUTS
    Object Data
    Results and messages are displayed to screen.
    Extracted files are saved to "$env:USERPROFILE\Downloads\Alternate Data Stream Files".

.LINK
    https://github.com/high101bro/
#>

param (
    [string[]]$ComputerName = 'localhost',
    [string[]]$Directory = ".\",
    [switch]$ExcludeZoneIdentifier,
    [switch]$ExtractADStoFile,
    [switch]$Recurse
)

Invoke-Command -ComputerName $ComputerName -ArgumentList $ComputerName,$Directory,$ExcludeZoneIdentifier,$ExtractADStoFile,$Recurse -ScriptBlock {
    param ($ComputerName,$Directory,$ExcludeZoneIdentifier,$ExtractADStoFile,$Recurse)
    $ErrorActionPreference = 'SilentlyContinue'
    $AlternateDataStreamFound = @()

    if ($Recurse) {
        $DirectoryFiles = Get-ChildItem -Path $Directory -Recurse
    }
    else {
        $DirectoryFiles = Get-ChildItem -Path $Directory
    }
    foreach ($File in $DirectoryFiles) {
        if ($ExcludeZoneIdentifier) {
            $AlternateDataStreamFound += Get-Item -Path $File.FullName -Stream * | Where-Object {$_.stream -ne ':$Data' -and $_.stream -ne 'Zone.Identifier'}
        }
        else {
            $AlternateDataStreamFound += Get-Item -Path $File.FullName -Stream *  | Where-Object {$_.stream -ne ':$Data'}
        }
    }
    $AlternateDataStreamFound | ForEach-Object { Get-Item $_.FullName -Force -Stream * -ErrorAction SilentlyContinue }
                 
    foreach ($Ads in $AlternateDataStreamFound) {
        $AdsData = Get-Content -Path "$($Ads.FileName)" -Stream "$($Ads.Stream)" -Raw
        if ($ExtractADStoFile) {$AdsData | Out-File "$(C:\$Ads.FileName)"}
        $Ads | Add-Member -MemberType NoteProperty -Name StreamData     -Value $AdsData
        $Ads | Add-Member -MemberType NoteProperty -Name PSComputerName -Value "$ComputerName"
        if     (($Ads.Stream -eq 'Zone.Identifier') -and ($Ads.StreamData -match 'ZoneID=0')) { 
            $Ads | Add-Member -MemberType NoteProperty -Name ZoneId -Value "[ZoneID 0] Local Machine Zone" 
            $Ads | Add-Member -MemberType NoteProperty -Name ZoneIdDescription -Value "[ZoneID 0] Local Machine Zone: The most trusted zone for content that exists on the local computer" 
        }
        elseif (($Ads.Stream -eq 'Zone.Identifier') -and ($Ads.StreamData -match 'ZoneID=1')) { 
            $Ads | Add-Member -MemberType NoteProperty -Name ZoneId -Value "[ZoneID 1] Local Intranet Zone" 
            $Ads | Add-Member -MemberType NoteProperty -Name ZoneIdDescription -Value "[ZoneID 1] Local Intranet Zone: For content located on an organization’s intranet" 
        }
        elseif (($Ads.Stream -eq 'Zone.Identifier') -and ($Ads.StreamData -match 'ZoneID=2')) { 
            $Ads | Add-Member -MemberType NoteProperty -Name ZoneId -Value "[ZoneID 2] Trusted Sites Zone" 
            $Ads | Add-Member -MemberType NoteProperty -Name ZoneIdDescription -Value "[ZoneID 2] Trusted Sites Zone: For content located on Web sites that are considered more reputable or trustworthy than other sites on the Internet" 
        }
        elseif (($Ads.Stream -eq 'Zone.Identifier') -and ($Ads.StreamData -match 'ZoneID=3')) { 
            $Ads | Add-Member -MemberType NoteProperty -Name ZoneId -Value "[ZoneID 3] Internet Zone" 
            $Ads | Add-Member -MemberType NoteProperty -Name ZoneIdDescription -Value "[ZoneID 3] Internet Zone: For Web sites on the Internet that do not belong to another zone" 
        }
        elseif (($Ads.Stream -eq 'Zone.Identifier') -and ($Ads.StreamData -match 'ZoneID=4')) { 
            $Ads | Add-Member -MemberType NoteProperty -Name ZoneId -Value "[ZoneID 4] Restricted Sites Zone" 
            $Ads | Add-Member -MemberType NoteProperty -Name ZoneIdDescription -Value "[ZoneID 4] Restricted Sites Zone: For Web sites that contain potentially-unsafe content" 
        }
        else {
            $Ads | Add-Member -MemberType NoteProperty -Name ZoneId -Value "N/A"
            $Ads | Add-Member -MemberType NoteProperty -Name ZoneIdDescription -Value "N/A"
        }
    }                     

    if ($ExtractADStoFile) {
        # Checks if the Alternate Data Stream Directory exists and creates it if it doesn't
        if (!(Test-Path -Path "$env:userprofile\Downloads\Alternate Data Stream Files")) {
            New-Item -ItemType Directory -Path "$env:userprofile\Downloads\Alternate Data Stream Files"
        }

        foreach ($ADS in $AlternateDataStreamFound) {
            $ADS | Select-Object -Property PSComputerName, FileName, Stream, @{Name="StreamDataSample";Expression={$($_.StreamData | out-string)[0..100] -join ''}}, ZoneId, ZoneIdDescription , Length
            Get-Content -Path $($ADS.FileName) -Stream $($ADS.Stream) -Raw `
            | Set-Content "$env:userprofile\Downloads\Alternate Data Stream Files\$(($ADS.FileName).split('\')[-1].split('.')[0]) - {$($ADS.Stream)}.txt"         
        }
        Write-Host "$($AlternateDataStreamFound.count) ADS Files have been extracted to the $("$env:userprofile\Downloads\Alternate Data Stream Files") directory." -ForegroundColor Yellow
    }
    else{
        $AlternateDataStreamFound | Select-Object -Property PSComputerName, FileName, Stream, @{Name="StreamDataSample";Expression={$($_.StreamData | out-string)[0..100] -join ''}}, ZoneId, ZoneIdDescription , Length
    }
}