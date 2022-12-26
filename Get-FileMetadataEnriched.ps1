[CmdletBinding()]
param (
    [Parameter(Position = 0, ValueFromPipeline)][Object] $Path,
    [switch] $All,
    [switch] $Signature,
    [switch] $Properties,
    [switch] $AlternateDataStreams,
    [switch] $Hashes
)
Process {
    foreach ($File in $Path) {
        $MetaDataObject = [ordered] @{}
        if ($File -is [string]) {
            $FileInformation = Get-ItemProperty -Path $File
        } elseif ($File -is [System.IO.DirectoryInfo]) {
            #Write-Warning "Get-FileMetaData - Directories are not supported. Skipping $File."
            continue
        } elseif ($File -is [System.IO.FileInfo]) {
            $FileInformation = $File
        } else {
            Write-Warning "Get-FileMetaData - Only files are supported. Skipping $File."
            continue
        }
        $ShellApplication = New-Object -ComObject Shell.Application
        $ShellFolder = $ShellApplication.Namespace($FileInformation.Directory.FullName)
        $ShellFile = $ShellFolder.ParseName($FileInformation.Name)
        $MetaDataProperties = [ordered] @{}
        0..400 | ForEach-Object -Process {
            $DataValue = $ShellFolder.GetDetailsOf($null, $_)
            $PropertyValue = (Get-Culture).TextInfo.ToTitleCase($DataValue.Trim()).Replace(' ', '')
            if ($PropertyValue -ne '') {
                $MetaDataProperties["$_"] = $PropertyValue
            }
        }
        foreach ($Key in $MetaDataProperties.Keys) {
            $Property = $MetaDataProperties[$Key]
            $Value = $ShellFolder.GetDetailsOf($ShellFile, [int] $Key)
            if ($Property -in 'Attributes', 'Folder', 'Type', 'SpaceFree', 'TotalSize', 'SpaceUsed') {
                continue
            }
            If (($null -ne $Value) -and ($Value -ne '')) {
                $MetaDataObject["$Property"] = $Value
            }
        }
        if ($FileInformation.VersionInfo) {
            $SplitInfo = ([string] $FileInformation.VersionInfo).Split([char]13)
            foreach ($Item in $SplitInfo) {
                $Property = $Item.Split(":").Trim()
                if ($Property[0] -and $Property[1] -ne '') {
                    $MetaDataObject["$($Property[0])"] = $Property[1]
                }
            }
        }
        $MetaDataObject["Attributes"] = $FileInformation.Attributes
        $MetaDataObject['IsReadOnly'] = $FileInformation.IsReadOnly
        $MetaDataObject['IsHidden'] = $FileInformation.Attributes -like '*Hidden*'
        $MetaDataObject['IsSystem'] = $FileInformation.Attributes -like '*System*'

        if ($Signature -or $All) {
            $DigitalSignature = Get-AuthenticodeSignature -FilePath $FileInformation.Fullname
            $MetaDataObject['SignatureCertificateSubject']      = $DigitalSignature.SignerCertificate.Subject
            $MetaDataObject['SignatureCertificateIssuer']       = $DigitalSignature.SignerCertificate.Issuer
            $MetaDataObject['SignatureCertificateSerialNumber'] = $DigitalSignature.SignerCertificate.SerialNumber
            $MetaDataObject['SignatureCertificateNotBefore']    = $DigitalSignature.SignerCertificate.NotBefore
            $MetaDataObject['SignatureCertificateNotAfter']     = $DigitalSignature.SignerCertificate.NotAfter
            $MetaDataObject['SignatureCertificateThumbprint']   = $DigitalSignature.SignerCertificate.Thumbprint
            $MetaDataObject['SignatureStatus']                  = $DigitalSignature.Status
            $MetaDataObject['IsOSBinary']                       = $DigitalSignature.IsOSBinary
        }


        if ($Properties -or $All) {
            $FileProperties = Get-ItemProperty -Path $Path | Select-Object -Property *
            $MetaDataObject['PSPath']             = $FileProperties.PSPath
            $MetaDataObject['PSParentPath']       = $FileProperties.PSParentPath
            $MetaDataObject['PSChildName']        = $FileProperties.PSChildName
            $MetaDataObject['PSDrive']            = $FileProperties.PSDrive
            $MetaDataObject['PSProvider']         = $FileProperties.PSProvider
            $MetaDataObject['PSIsContainer']      = $FileProperties.PSIsContainer
            $MetaDataObject['Mode']               = $FileProperties.Mode
            $MetaDataObject['VersionInfo']        = $FileProperties.VersionInfo            
            $MetaDataObject['Target']             = $FileProperties.Target
            $MetaDataObject['LinkType']           = $FileProperties.LinkType
            $MetaDataObject['Name']               = $FileProperties.Name
            $MetaDataObject['BaseName']           = $FileProperties.BaseName
            $MetaDataObject['FullName']           = $RetrievedFileProperties.FullName
            $MetaDataObject['DirectoryName']     = $FileProperties.DirectoryName
            $MetaDataObject['Directory']         = $FileProperties.Directory
            $MetaDataObject['IsReadOnly']        = $FileProperties.IsReadOnly
            $MetaDataObject['Exists']            = $FileProperties.Exists
            $MetaDataObject['FullName']          = $FileProperties.FullName
            $MetaDataObject['Extension']         = $FileProperties.Extension
            $MetaDataObject['CreationTime']      = $FileProperties.CreationTime
            $MetaDataObject['CreationTimeUtc']   = $FileProperties.CreationTimeUtc
            $MetaDataObject['LastAccessTime']    = $FileProperties.LastAccessTime
            $MetaDataObject['LastAccessTimeUtc'] = $FileProperties.LastAccessTimeUtc
            $MetaDataObject['LastWriteTime']     = $FileProperties.LastWriteTime
            $MetaDataObject['LastWriteTimeUtc']  = $FileProperties.LastWriteTimeUtc
            $MetaDataObject['Attributes']        = $FileProperties.Attributes
            $MetaDataObject['Length']            = $FileProperties.Length
            $MetaDataObject['Bytes']             = "$($RetrievedFileProperties.Length) Bytes"
            $MetaDataObject['KiloBytes(KB)']     = "$([math]::Round(($RetrievedFileProperties.Length / 1KB),3)) KB"
            $MetaDataObject['MegaBytes(MB)']     = "$([math]::Round(($RetrievedFileProperties.Length / 1MB),3)) MB"
            $MetaDataObject['GigaBytes(GB)']     = "$([math]::Round(($RetrievedFileProperties.Length / 1GB),3)) GB"
            # $MetaDataObject['FileVersionRaw']     = $RetrievedFileProperties.VersionInfo.FileVersionRaw
            # $MetaDataObject['ProductVersionRaw']  = $RetrievedFileProperties.VersionInfo.ProductVersionRaw
            # $MetaDataObject['Comments']           = $RetrievedFileProperties.VersionInfo.Comments
            # $MetaDataObject['CompanyName']        = $RetrievedFileProperties.VersionInfo.CompanyName
            # $MetaDataObject['FileBuildPart']      = $RetrievedFileProperties.VersionInfo.FileBuildPart
            # $MetaDataObject['FileDescription']    = $RetrievedFileProperties.VersionInfo.FileDescription
            # $MetaDataObject['FileMajorPart']      = $RetrievedFileProperties.VersionInfo.FileMajorPart
            # $MetaDataObject['FileMinorPart']      = $RetrievedFileProperties.VersionInfo.FileMinorPart
            # $MetaDataObject['FileName']           = $RetrievedFileProperties.VersionInfo.FileName
            # $MetaDataObject['FilePrivatePart']    = $RetrievedFileProperties.VersionInfo.FilePrivatePart
            # $MetaDataObject['FileVersion']        = $RetrievedFileProperties.VersionInfo.FileVersion
            # $MetaDataObject['InternalName']       = $RetrievedFileProperties.VersionInfo.InternalName
            # $MetaDataObject['IsDebug']            = $RetrievedFileProperties.VersionInfo.IsDebug
            # $MetaDataObject['IsPatched']          = $RetrievedFileProperties.VersionInfo.IsPatched
            # $MetaDataObject['IsPrivateBuild']     = $RetrievedFileProperties.VersionInfo.IsPrivateBuild
            # $MetaDataObject['IsPreRelease']       = $RetrievedFileProperties.VersionInfo.IsPreRelease
            # $MetaDataObject['IsSpecialBuild']     = $RetrievedFileProperties.VersionInfo.IsSpecialBuild
            # $MetaDataObject['Language']           = $RetrievedFileProperties.VersionInfo.Language
            # $MetaDataObject['LegalCopyright']     = $RetrievedFileProperties.VersionInfo.LegalCopyright
            # $MetaDataObject['LegalTrademarks']    = $RetrievedFileProperties.VersionInfo.LegalTrademarks
            # $MetaDataObject['OriginalFilename']   = $RetrievedFileProperties.VersionInfo.OriginalFilename
            # $MetaDataObject['PrivateBuild']       = $RetrievedFileProperties.VersionInfo.PrivateBuild
            # $MetaDataObject['ProductBuildPart']   = $RetrievedFileProperties.VersionInfo.ProductBuildPart
            # $MetaDataObject['ProductMajorPart']   = $RetrievedFileProperties.VersionInfo.ProductMajorPart
            # $MetaDataObject['ProductMinorPart']   = $RetrievedFileProperties.VersionInfo.ProductMinorPart
            # $MetaDataObject['ProductName']        = $RetrievedFileProperties.VersionInfo.ProductName
            # $MetaDataObject['ProductPrivatePart'] = $RetrievedFileProperties.VersionInfo.ProductPrivatePart
            # $MetaDataObject['ProductVersion']     = $RetrievedFileProperties.VersionInfo.ProductVersion
            # $MetaDataObject['SpecialBuild']       = $RetrievedFileProperties.VersionInfo.SpecialBuild
        }

        if ($Hashes -or $All) {
            $MetaDataObject['MACTripleDES'] = (Get-FileHash -Algorithm "MACTripleDES" -Path $Path).Hash
            $MetaDataObject['MD5']          = (Get-FileHash -Algorithm "MD5" -Path $Path).Hash
            $MetaDataObject['RIPEMD160']    = (Get-FileHash -Algorithm "RIPEMD160" -Path $Path).Hash
            $MetaDataObject['SHA1']         = (Get-FileHash -Algorithm "SHA1" -Path $Path).Hash
            $MetaDataObject['SHA256']       = (Get-FileHash -Algorithm "SHA256" -Path $Path).Hash
            $MetaDataObject['SHA384']       = (Get-FileHash -Algorithm "SHA384" -Path $Path).Hash
            $MetaDataObject['SHA512']       = (Get-FileHash -Algorithm "SHA512" -Path $Path).Hash
        }

        if ($AlternateDataStreams -or $All) {
            $Ads = Get-Item $File -Force -Stream * -ErrorAction SilentlyContinue | Where-Object stream -ne ':$DATA'
            $AdsData = Get-Content -Path $Ads.FileName -Stream $Ads.Stream
            #too much... $Ads | Add-Member -MemberType NoteProperty -Name StreamData -Value $AdsData

            $MetaDataObject['ADS_Head(1000)'] = ($AdsData | Out-String)[0..1000] -join ""

            switch -Regex ($MetaDataObject.'ADS_Head(1000)') {
                "ZoneID=0" { $MetaDataObject['AlternateDataStream'] = "[ZoneID 0] Local Machine Zone: The most trusted zone for content that exists on the local computer." }
                "ZoneID=1" { $MetaDataObject['AlternateDataStream'] = "[ZoneID 1] Local Intranet Zone: For content located on an organizations intranet." }
                "ZoneID=2" { $MetaDataObject['AlternateDataStream'] = "[ZoneID 2] Trusted Sites Zone: For content located on Web sites that are considered more reputable or trustworthy than other sites on the Internet." }
                "ZoneID=3" { $MetaDataObject['AlternateDataStream'] = "[ZoneID 3] Internet Zone: For Web sites on the Internet that do not belong to another zone." }
                "ZoneID=4" { $MetaDataObject['AlternateDataStream'] = "[ZoneID 4] Restricted Sites Zone: For Web sites that contain potentially-unsafe content." }
            }
            
            $MetaDataObject['ADS_Size'] = $(
                if     ($Ads.Length -gt 1000000000) { "$([Math]::Round($($Ads.Length / 1gb),2)) GB" }
                elseif ($Ads.Length -gt 1000000)    { "$([Math]::Round($($Ads.Length / 1mb),2)) MB" }
                elseif ($Ads.Length -gt 1000)       { "$([Math]::Round($($Ads.Length / 1kb),2)) KB" }
                elseif ($Ads.Length -le 1000)       { "$($Ads.Length) Bytes" }
            )
        }

        [PSCustomObject] $MetaDataObject
    }
}