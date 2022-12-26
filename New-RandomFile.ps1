<#
.Synopsis
    Creates a random file.

.Description
    Creates a file with random data at a specified location.

.Parameter Path
    Enter the file path to save the data. The default path is the present working directory (pwd).

.Parameter FileName
    Enter the filename to be saved as. The default filename is Random-File.txt.

.Parameter FileSize
    Enter the file size of the file to be generated. The default file size is 1kb.

.Example
    1) Default use.
    ./New-RandomFile.ps1

.Example
    2) Specify arguments.
    ./New-RandomFile.ps1 -Path . -FileName random.txt -FileSize 1GB
#>
Param(
    $Path = (Resolve-Path '.').Path,
    $FileName = [guid]::NewGuid().Guid + '.txt',
    $FileSize = 1kb
) 
#(1..($FileSize/128)).foreach({-join ([guid]::NewGuid().Guid + [guid]::NewGuid().Guid + [guid]::NewGuid().Guid + [guid]::NewGuid().Guid -Replace "-").SubString(1, 126) }) | Set-Content "$Path\$FileName"

$Chunk = { [guid]::NewGuid().Guid + [guid]::NewGuid().Guid + [guid]::NewGuid().Guid + [guid]::NewGuid().Guid +
           [guid]::NewGuid().Guid + [guid]::NewGuid().Guid + [guid]::NewGuid().Guid + [guid]::NewGuid().Guid +
           [guid]::NewGuid().Guid + [guid]::NewGuid().Guid + [guid]::NewGuid().Guid + [guid]::NewGuid().Guid +
           [guid]::NewGuid().Guid + [guid]::NewGuid().Guid + [guid]::NewGuid().Guid + [guid]::NewGuid().Guid +
           [guid]::NewGuid().Guid + [guid]::NewGuid().Guid + [guid]::NewGuid().Guid + [guid]::NewGuid().Guid +
           [guid]::NewGuid().Guid + [guid]::NewGuid().Guid + [guid]::NewGuid().Guid + [guid]::NewGuid().Guid +
           [guid]::NewGuid().Guid + [guid]::NewGuid().Guid + [guid]::NewGuid().Guid + [guid]::NewGuid().Guid +
           [guid]::NewGuid().Guid + [guid]::NewGuid().Guid + [guid]::NewGuid().Guid + [guid]::NewGuid().Guid -Replace "-" }

$Chunks = [math]::Ceiling($FileSize/1kb)

[io.file]::WriteAllText("$Path\$FileName","$(-Join (1..($Chunks)).foreach({ $Chunk.Invoke() }))")

# Write-Warning "New-RandomFile: $Path\$FileName"
