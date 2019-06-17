Set-Content -Path "$env:userprofile\desktop\ADS_File_with_PowerShell_Script.txt"-value "This file Contains an embedded PowerShell script within an Alternate Data Stream.`r`nTwo notepad.exe windows should appear."
Foreach ($n in (1..2)) { Start-Process notepad.exe "$env:userprofile\desktop\ADS_File_with_PowerShell_Script.txt" }

