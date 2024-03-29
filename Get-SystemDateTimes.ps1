<#
.Description
    Compiles various time related data into one easy to read results
#>

$os = $null
$GetTimeZone = $null
$os = Get-WmiObject win32_operatingsystem
$GetTimeZone = Get-Timezone
if ($GetTimeZone) {
    $DateTimes = [PSCustomObject]@{
        LastBootUpTime             = $os.ConvertToDateTime($os.LastBootUpTime)
        InstallDate                = $os.ConvertToDateTime($os.InstallDate)
        LocalDateTime              = $os.ConvertToDateTime($os.LocalDateTime)
        TimeZone                   = $GetTimeZone.StandardName
        BaseUtcOffset              = $GetTimeZone.BaseUtcOffset
        SupportsDaylightSavingTime = $GetTimeZone.SupportsDaylightSavingTime
    }
    $DateTimes | Select-Object @{n='ComputerName';E={$env:COMPUTERNAME}}, LocalDateTime, LastBootUpTime, InstallDate, TimeZone, BaseUtcOffset, SupportsDaylightSavingTime
}
else {
    $DateTimes = [PSCustomObject]@{
        LastBootUpTime  = $os.ConvertToDateTime($os.LastBootUpTime)
        InstallDate     = $os.ConvertToDateTime($os.InstallDate)
        LocalDateTime   = $os.ConvertToDateTime($os.LocalDateTime)
        CurrentTimeZone = $os.CurrentTimeZone
    }
    $DateTimes | Select-Object @{n='ComputerName';E={$env:COMPUTERNAME}}, LocalDateTime, LastBootUpTime, InstallDate, CurrentTimeZone
}












# SIG # Begin signature block
# MIIFuAYJKoZIhvcNAQcCoIIFqTCCBaUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUN/KxEAl7mj5qwk0GDdQLbm0m
# 4o+gggM6MIIDNjCCAh6gAwIBAgIQeugH5LewQKBKT6dPXhQ7sDANBgkqhkiG9w0B
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
# NwIBFTAjBgkqhkiG9w0BCQQxFgQUgAHZ1CiyvauAroyXvw7F8lcFBoUwDQYJKoZI
# hvcNAQEBBQAEggEAcG40YS8rZ9tpRUwNb2pRPwJAgSIsJtaYq6JG4PqRvcs7Jqzd
# VqbtceCHrQ4oAxdoPilu8EkRZtY2pOGbtYEF5/L9+uJi5wICQhW5PE6z53sLefTy
# m8rAkKiWWu3Mk2fSfJ1m8dY+geXr7dFOy9Ign/nIyDtaybPZFgPjNUZOVSXBojYu
# TLHiw+0aHNM1eVXOXkCJMqs2OMzQIYvyoWwHfSrDUwQI+EcEzmq0SNtmJ9P/6BfW
# jvnAhiI56X1ilsGKlpHkWJT6vNbTQf1Rfj00YS70zPi0q2XGoSbv/ibpvmT4+upS
# YcXiwmL/gaWGy7v5DB7rhu+PhVT2YbO13DDW3A==
# SIG # End signature block
