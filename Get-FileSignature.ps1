<#
.SYNOPSIS
    Obtains file signature information on file, such as MZ if it's an executable.

.LINKS
    https://mcpmag.com/articles/2018/07/25/file-signatures-using-powershell.aspx
#>
[CmdletBinding()]
Param(
    [Parameter(
        Position=0,
        Mandatory=$true, 
        ValueFromPipelineByPropertyName=$true,
        ValueFromPipeline=$True)]
    [Alias("PSPath","FullName")]
        [string[]]$Path,
    [Parameter()]
    [Alias('Filter')]
        [string]$HexFilter = "*",
    [Parameter()]
        [int]$ByteLimit = 2,
    [Parameter()]
    [Alias('OffSet')]
        [int]$ByteOffset = 0
)
Begin {
    #Determine how many bytes to return if using the $ByteOffset
    $TotalBytes = $ByteLimit + $ByteOffset

    #Clean up filter so we can perform a regex match
    #Also remove any spaces so we can make it easier to match
    [regex]$pattern = ($HexFilter -replace '\*','.*') -replace '\s',''
}
Process {  
    ForEach ($item in $Path) { 
        Try {                     
            $item = Get-Item -LiteralPath (Convert-Path $item) -Force -ErrorAction Stop
        } Catch {
            Write-Warning "$($item): $($_.Exception.Message)"
            Return
        }
        If (Test-Path -Path $item -Type Container) {
            Write-Warning ("Cannot find signature on directory: {0}" -f $item)
        } Else {
            Try {
                If ($Item.length -ge $TotalBytes) {
                    #Open a FileStream to the file; this will prevent other actions against file until it closes
                    $filestream = New-Object IO.FileStream($Item, [IO.FileMode]::Open, [IO.FileAccess]::Read)

                    #Determine starting point
                    [void]$filestream.Seek($ByteOffset, [IO.SeekOrigin]::Begin)

                    #Create Byte buffer to read into and then read bytes from starting point to pre-determined stopping point
                    $bytebuffer = New-Object "Byte[]" ($filestream.Length - ($filestream.Length - $ByteLimit))
                    [void]$filestream.Read($bytebuffer, 0, $bytebuffer.Length)

                    #Create string builder objects for hex and ascii display
                    $hexstringBuilder = New-Object Text.StringBuilder
                    $stringBuilder = New-Object Text.StringBuilder

                    #Begin converting bytes
                    For ($i=0;$i -lt $ByteLimit;$i++) {
                        If ($i%2) {
                            [void]$hexstringBuilder.Append(("{0:X}" -f $bytebuffer[$i]).PadLeft(2, "0"))
                        } Else {
                            If ($i -eq 0) {
                                [void]$hexstringBuilder.Append(("{0:X}" -f $bytebuffer[$i]).PadLeft(2, "0"))
                            } Else {
                                [void]$hexstringBuilder.Append(" ")
                                [void]$hexstringBuilder.Append(("{0:X}" -f $bytebuffer[$i]).PadLeft(2, "0"))
                            }        
                        }
                        If ([char]::IsLetterOrDigit($bytebuffer[$i])) {
                            [void]$stringBuilder.Append([char]$bytebuffer[$i])
                        } Else {
                            [void]$stringBuilder.Append(".")
                        }
                    }
                    If (($hexstringBuilder.ToString() -replace '\s','') -match $pattern) {
                        $object = [pscustomobject]@{
                            Name = ($item -replace '.*\\(.*)','$1')
                            FullName = $item
                            HexSignature = $hexstringBuilder.ToString()
                            ASCIISignature = $stringBuilder.ToString()
                            Length = $item.length
                            Extension = $Item.fullname -replace '.*\.(.*)','$1'
                        }
                        $object.pstypenames.insert(0,'System.IO.FileInfo.Signature')
                        Write-Output $object
                    }
                } ElseIf ($Item.length -eq 0) {
                    Write-Warning ("{0} has no data ({1} bytes)!" -f $item.name,$item.length)
                } Else {
                    Write-Warning ("{0} size ({1}) is smaller than required total bytes ({2})" -f $item.name,$item.length,$TotalBytes)
                }
            } Catch {
                Write-Warning ("{0}: {1}" -f $item,$_.Exception.Message)
            }

            #Close the file stream so the file is no longer locked by the process
            $FileStream.Close()
        }
    }        
}
