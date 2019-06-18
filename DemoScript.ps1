Set-Content -Path "$env:userprofile\desktop\ADS_File_with_PowerShell_Script.txt"-value "$(Get-Process | Out-String; Get-Service | Out-String)"

Foreach ($n in (1..2)) { Start-Process notepad.exe "$env:userprofile\desktop\ADS_File_with_PowerShell_Script.txt" }
<#
Get-WmiObject -Class Win32_ComputerSystem
Get-WmiObject -Class Win32_UserAccount
Get-WmiObject -Class Win32_Group
Get-WmiObject -Class Win32_Process
Get-WmiObject -Class Win32_Service
Get-WmiObject -Class Win32_QuickFixEngineering
Get-WmiObject -Class Win32_Product
Get-WmiObject -class Win32_StartupCommand
Get-DnsClientCache
Get-NetAdapter
Get-NetIPConfiguration
Get-NetTCPConnection
Get-NetFirewallProfile
Get-NetFirewallRule -Enabled True -Direction Inbound -Action Allow
Get-NetFirewallRule -Enabled True -Direction Outbound -Action Allow
Get-WmiObject -Class Win32_Share
Get-WmiObject -Class Win32_DiskDrive
Get-WmiObject -Class Win32_Processor
Get-WmiObject -Class Win32_BIOS
Get-WmiObject -Class Win32_PhysicalMemoryArray
Get-WmiObject -Class Win32_LogicalDisk
Get-WmiObject -Class Win32_Systemdriver | FT -AutoSize
Get-WmiObject -Class Win32_BaseBoard
Get-WmiObject -Class Win32_PnPEntity 
#>
