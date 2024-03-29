$ErrorActionPreference = 'SilentlyContinue'

#$env:computername
#$ErrorActionPreference = 'SilentlyContinue'

$SHA256  = [System.Security.Cryptography.HashAlgorithm]::Create("SHA256")
$MD5     = [System.Security.Cryptography.HashAlgorithm]::Create("MD5")
$regkeys = @(
'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunServices',
'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce',
'HCCU:\Software\Microsoft\Windows\Curre ntVersion\RunOnce\Setup',
'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon',
'HKLM:\Software\Microsoft\Active Setup\Installed Components',
'HKLM:\System\CurrentControlSet\Servic es\VxD',
'HKCU:\Control Panel\Desktop',
'HKLM:\System\CurrentControlSet\Control\Session Manager',
'HKLM:\System\CurrentControlSet\Services',
'HKLM:\System\CurrentControlSet\Services\Winsock2\Parameters\Protocol_Catalog\Catalog_Entries',
'HKLM:\System\Control\WOW\cmdline',
'HKLM:\System\Control\WOW\wowcmdline',
'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Userinit',
'HKLM:\Software\Microsoft\Windows\Curr entVersion\ShellServiceObjectDelayLoad',
'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows\run',
'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows\load',
'HKCU:\Software\Microsoft\Windows\Curre ntVersion\Policies\Explorer\run',
'HLKM:\Software\Microsoft\Windows\Curr entVersion\Policies\Explorer\run'
)
$Startups = @()
foreach ($key in $regkeys) {
    $entry = Get-ItemProperty -Path $key
    $entry = $entry | Select-Object * -ExcludeProperty PSPath, PSParentPath, PSChildName, PSDrive, PSProvider
    #$entry.psobject.Properties |ft
    foreach($item in $entry.PSObject.Properties) {
        $value = $item.value.replace('"', '')
        # The entry could be an actual path
        if(Test-Path $value) {

            $filebytes   = [system.io.file]::ReadAllBytes($value)
            $AuthenticodeSignature = Get-AuthenticodeSignature $value
            $HashObject  = New-Object PSObject -Property @{
                Name     = Split-Path $Value -Leaf
                Path     = $value
                SignatureStatus = $AuthenticodeSignature.Status
                SignatureCompany = ($AuthenticodeSignature.SignerCertificate.SubjectName.Name -split ',')[0].TrimStart('CN=')
                MD5      = [System.BitConverter]::ToString($md5.ComputeHash($filebytes)) -replace "-", "";
                SHA256   = [System.BitConverter]::ToString($sha256.ComputeHash($filebytes)) -replace "-","";
                PSComputerName = $env:COMPUTERNAME
            }
            $Startups += $HashObject
        }
    }
}
$Startups | Select-Object PSComputerName, Name, Path, MD5, SHA256, SignatureStatus, SignatureCompany










# SIG # Begin signature block
# MIIFuAYJKoZIhvcNAQcCoIIFqTCCBaUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvHmfkW7SmZC5an8MDbU+k5k2
# y9egggM6MIIDNjCCAh6gAwIBAgIQeugH5LewQKBKT6dPXhQ7sDANBgkqhkiG9w0B
# AQUFADAzMTEwLwYDVQQDDChQb1NoLUVhc3lXaW4gQnkgRGFuIEtvbW5pY2sgKGhp
# Z2gxMDFicm8pMB4XDTIxMTIxNDA1MDIwMFoXDTMxMTIxNDA1MTIwMFowMzExMC8G
# A1UEAwwoUG9TaC1FYXN5V2luIEJ5IERhbiBLb21uaWNrIChoaWdoMTAxYnJvKTCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALvIxUDFEVGB/G0FXPryoNlF
# dA65j5jPEFM2R4468rjlTVsNYUOR+XvhjmhpggSQa6SzvXtklUJIJ6LgVUpt/0C1
# zlr1pRwTvsd3svI7FHTbJahijICjCv8u+bFcAR2hH3oHFZTqvzWD1yG9FGCw2pq3
# h4ahxtYBd1+/n+jOtPUoMzcKIOXCUe4Cay+xP8k0/OLIVvKYRlMY4B9hvTW2CK7N
# fPnvFpNFeGgZKPRLESlaWncbtEBkexmnWuferJsRtjqC75uNYuTimLDSXvNps3dJ
# wkIvKS1NcxfTqQArX3Sg5qKX+ZR21uugKXLUyMqXmVo2VEyYJLAAAITEBDM8ngUC
# AwEAAaNGMEQwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMB0G
# A1UdDgQWBBSDJIlo6BcZ7KJAW5hoB/aaTLxFzTANBgkqhkiG9w0BAQUFAAOCAQEA
# ouCzal7zPn9vc/C9uq7IDNb1oNbWbVlGJELLQQYdfBE9NWmXi7RfYNd8mdCLt9kF
# CBP/ZjHKianHeZiYay1Tj+4H541iUN9bPZ/EaEIup8nTzPbJcmDbaAGaFt2PFG4U
# 3YwiiFgxFlyGzrp//sVnOdtEtiOsS7uK9NexZ3eEQfb/Cd9HRikeUG8ZR5VoQ/kH
# 2t2+tYoCP4HsyOkEeSQbnxlO9s1jlSNvqv4aygv0L6l7zufiKcuG7q4xv/5OvZ+d
# TcY0W3MVlrrNp1T2wxzl3Q6DgI+zuaaA1w4ZGHyxP8PLr6lMi6hIugI1BSYVfk8h
# 7KAaul5m+zUTDBUyNd91ojGCAegwggHkAgEBMEcwMzExMC8GA1UEAwwoUG9TaC1F
# YXN5V2luIEJ5IERhbiBLb21uaWNrIChoaWdoMTAxYnJvKQIQeugH5LewQKBKT6dP
# XhQ7sDAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkq
# hkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGC
# NwIBFTAjBgkqhkiG9w0BCQQxFgQUSfQNtCpJDjhTSUh+h2M7idTTcr8wDQYJKoZI
# hvcNAQEBBQAEggEArPt/y6uLZBFqOehab0IBu7kU6yZ9ggKi8LwzKjUIWbBOL8Dc
# aYb/DxCBOBV45zKjnVzSglMbFgfB0KfVWOFY/DSpwTZxhas9dzuu/K6pv/a18GAk
# bghx9XZogDjgrgYc/qrT7RZANPcLgJiX8nsZfwrj/7Ly1FrxCX16nnWCUmIQtORf
# h2fALhcQXnFOcI8CZmYfEn1bi5PmJpjmjpGIyUXaSC2tpVPPFt8jcCmj4VF4yq3V
# 8KzY2g202xSiYg1NSo7T1YaWc8fhKsp20bXv9n/HkqEduUiSRr7rKVD1zTA9NJKi
# esekD5y3yWAZyaNyDkrHtED9KLCwoEuYpHiEEg==
# SIG # End signature block
