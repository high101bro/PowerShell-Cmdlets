$ScheduledTasks = Get-ScheduledTask `
| Select-Object -Property State, Actions, Author, Date, Description, Documentation, Principal, SecurityDescriptor, Settings, Source, TaskName, TaskPath, Triggers, URI, Version, PSComputerName

foreach ($Task in $ScheduledTasks) {
    $Task | Add-Member -MemberType NoteProperty -Name Settings -Value $($Task.Settings | Out-String).trim(' ').trim("`r`n") -Force -PassThru `
          | Add-Member -MemberType NoteProperty -Name SettingsIdleSettings -Value $($Task.Settings.IdleSettings | Out-String).trim(' ').trim("`r`n") -Force -PassThru `
          | Add-Member -MemberType NoteProperty -Name SettingsNetworkSettings -Value $($Task.Settings.NetworkSettings | Out-String).trim(' ').trim("`r`n") -Force -PassThru `
          | Add-Member -MemberType NoteProperty -Name Principal -Value $($Task.Principal | Out-String).trim(' ').trim("`r`n") -Force -PassThru `
          | Add-Member -MemberType NoteProperty -Name Actions -Value $($Task.Actions | Out-String).trim(' ').trim("`r`n") -Force -PassThru `
          | Add-Member -MemberType NoteProperty -Name TriggersCount -Value $Task.Triggers.Count -Force -PassThru `
          | Add-Member -MemberType NoteProperty -Name Triggers -Value $($Task.Triggers | Out-String).trim(' ').trim("`r`n") -Force -PassThru `
          | Add-Member -MemberType NoteProperty -Name TriggersRepetition -Value $($Task.Triggers.Repetition | Out-String).trim(' ').trim("`r`n") -Force
}

$ScheduledTasks












# SIG # Begin signature block
# MIIFuAYJKoZIhvcNAQcCoIIFqTCCBaUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUNeepygXtYjgvhwFdqIjh1HFK
# ggKgggM6MIIDNjCCAh6gAwIBAgIQeugH5LewQKBKT6dPXhQ7sDANBgkqhkiG9w0B
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
# NwIBFTAjBgkqhkiG9w0BCQQxFgQUxMrHeDiEQKKlqtUDtFgDuafi188wDQYJKoZI
# hvcNAQEBBQAEggEALhIiqYvy+D98mpMur/EJfsAPjWM0CyuqWZRttRlwkbUav1Gd
# B9y0E5cU9JWwuKrtr6FBSsEw97QUrd4YagHRK3Po5RdA7LgdNzklKdsEyQ1/cUuY
# +C69pDv5ywv7C1l2S1g4Jk82oifUdz1HdLK99w7pD15hTUUx2RqQbE8tLe0TPpSv
# lE2+4wMxIcekBNR3ZFRBZ+EIV1MF3SI3K7KpfkAYbd/oYkvCEM6Ud9pwf61ymKB5
# b6X6UAbwVx3DgPYqsHcbMeIFvXGM4svXm09E75tu3IVT2tQm85r4HBIywF2nEW/j
# WWGA42RToFzgUfsppccc+pAjAjSLC4jTRtNlIA==
# SIG # End signature block
