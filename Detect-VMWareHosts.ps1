$VMwareDetected   = $False
$VMNetworkAdapter = $(Get-WmiObject Win32_NetworkAdapter -Filter 'Manufacturer LIKE "%VMware%" OR Name LIKE "%VMware%"')
$VMBios           = $(Get-WmiObject Win32_BIOS -Filter 'SerialNumber LIKE "%VMware%"')
$VMWareService    = $(Get-Service | Where-Object {$_.Name -match "vmware" -and $_.Status -eq 'Running'} | Select-Object -ExpandProperty Name)
$VMWareProcess    = $(Get-Process | Where-Object Name -match "vmware" | Select-Object -ExpandProperty Name)
$VMToolsProcess   = $(Get-Process | Where-Object Name -match "vmtoolsd" | Select-Object -ExpandProperty Name)
if($VMNetworkAdapter -or $VMBios -or $VMToolsProcess) {
    $VMwareDetected = $True
}
[PSCustomObject]@{
    PSComputerName   = $env:COMPUTERNAME
    Name             = 'VMWare Detection'
    VMWareDetected   = $VMwareDetected
    VMNetworkAdapter = $VMNetworkAdapter
    VMBIOS           = $VMBIOS
    VMWareService    = $VMWareService
    VMWareProcess    = $VMWareProcess
    VMToolsProcess   = $VMToolsProcess
}












# SIG # Begin signature block
# MIIFuAYJKoZIhvcNAQcCoIIFqTCCBaUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUqV3GEFFcTdVS/+xuq+//eirM
# 4DugggM6MIIDNjCCAh6gAwIBAgIQeugH5LewQKBKT6dPXhQ7sDANBgkqhkiG9w0B
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
# NwIBFTAjBgkqhkiG9w0BCQQxFgQUkP+UgqJwoIKqFmKTeBqVaxfIy2kwDQYJKoZI
# hvcNAQEBBQAEggEAHjIqX/tO4y2A/BdAn0mQQ8/hlvfBRHLmp9WuhfbQrx7piA1n
# IhMd5HUyYZziQNSSHTRk9tGfsYWwuI/IN6SvWAJryOCOihndn+sdXZ5pxETOEt6B
# P3v2J0rHiZ0chkuXPTz5i9pbkE6c92tL8fj/ncZVfwQH8i8z6WoDu8D8dBLClzMT
# KQdlribcAFmNU4zPFmdxzaYLoELRbVd+UgelvbcZFUNXfMeJM3RSTDQa+bZ5nw6B
# vPrQ3IQC6TwZr6tqeGJlcxkn86Gb580yuUAwNNwyYuKwLGUO9xHaoBaDtZ9pD1PF
# F2tOw+CgnI2Sk9LnKKSibKBnZR4V3rt+mNbNbQ==
# SIG # End signature block
