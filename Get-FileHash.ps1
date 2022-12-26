[CmdletBinding(DefaultParameterSetName = "Path", HelpURI = "https://go.microsoft.com/fwlink/?LinkId=517145")]
param(
    [Parameter(Mandatory, ParameterSetName="Path", Position = 0)]
    [System.String[]]
    $Path,

    [Parameter(Mandatory, ParameterSetName="LiteralPath", ValueFromPipelineByPropertyName = $true)]
    [Alias("PSPath")]
    [System.String[]]
    $LiteralPath,

    [Parameter(Mandatory, ParameterSetName="Stream")]
    [System.IO.Stream]
    $InputStream,

    [ValidateSet("SHA1", "SHA256", "SHA384", "SHA512", "MACTripleDES", "MD5", "RIPEMD160")]
    [System.String]
    $Algorithm="SHA256"
)

begin
{
    # Construct the strongly-typed crypto object

    # First see if it has a FIPS algorithm
    $hasherType = "System.Security.Cryptography.${Algorithm}CryptoServiceProvider" -as [Type]
    if ($hasherType)
    {
        $hasher = $hasherType::New()
    }
    else
    {
        # Check if the type is supported in the current system
        $algorithmType = "System.Security.Cryptography.${Algorithm}" -as [Type]
        if ($algorithmType)
        {
            if ($Algorithm -eq "MACTripleDES")
            {
                $hasher = $algorithmType::New()
            }
            else
            {
                $hasher = $algorithmType::Create()
            }
        }
        else
        {
            $errorId = "AlgorithmTypeNotSupported"
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
            $errorMessage = [Microsoft.PowerShell.Commands.UtilityResources]::AlgorithmTypeNotSupported -f $Algorithm
            $exception = [System.InvalidOperationException]::New($errorMessage)
            $errorRecord = [System.Management.Automation.ErrorRecord]::New($exception, $errorId, $errorCategory, $null)
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }

    function GetStreamHash
    {
        param(
            [System.IO.Stream]
            $InputStream,

            [System.String]
            $RelatedPath,

            [System.Security.Cryptography.HashAlgorithm]
            $Hasher)

        # Compute file-hash using the crypto object
        [Byte[]] $computedHash = $Hasher.ComputeHash($InputStream)
        [string] $hash = [BitConverter]::ToString($computedHash) -replace '-',''

        if ($RelatedPath -eq $null)
        {
            $retVal = [PSCustomObject] @{
                Algorithm = $Algorithm.ToUpperInvariant()
                Hash = $hash
            }
        }
        else
        {
            $retVal = [PSCustomObject] @{
                Algorithm = $Algorithm.ToUpperInvariant()
                Hash = $hash
                Path = $RelatedPath
            }
        }
        $retVal.psobject.TypeNames.Insert(0, "Microsoft.Powershell.Utility.FileHash")
        $retVal
    }
}

process
{
    if($PSCmdlet.ParameterSetName -eq "Stream")
    {
        GetStreamHash -InputStream $InputStream -RelatedPath $null -Hasher $hasher
    }
    else
    {
        $pathsToProcess = @()
        if($PSCmdlet.ParameterSetName  -eq "LiteralPath")
        {
            $pathsToProcess += Resolve-Path -LiteralPath $LiteralPath | Foreach-Object ProviderPath
        }
        if($PSCmdlet.ParameterSetName -eq "Path")
        {
            $pathsToProcess += Resolve-Path $Path | Foreach-Object ProviderPath
        }

        foreach($filePath in $pathsToProcess)
        {
            if(Test-Path -LiteralPath $filePath -PathType Container)
            {
                continue
            }

            try
            {
                # Read the file specified in $FilePath as a Byte array
                [system.io.stream]$stream = [system.io.file]::OpenRead($filePath)
                GetStreamHash -InputStream $stream  -RelatedPath $filePath -Hasher $hasher
            }
            catch [Exception]
            {
                $errorMessage = [Microsoft.PowerShell.Commands.UtilityResources]::FileReadError -f $FilePath, $_
                Write-Error -Message $errorMessage -Category ReadError -ErrorId "FileReadError" -TargetObject $FilePath
                return
            }
            finally
            {
                if($stream)
                {
                    $stream.Dispose()
                }
            }
        }
    }
}