
###################
# PoSh-ACME Light #
###################

$form = New-Object Windows.Forms.Form -Property @{
    Name          = "EventLog DateTime Picker"
    Text          = "EventLog DateTime Picker"
    Size          = New-Object Drawing.Size 275, 190
    StartPosition = [Windows.Forms.FormStartPosition]::CenterScreen
    Topmost       = $true
}

$WmiCommands           = New-Object System.Windows.Forms.ComboBox -Property @{
    Name               = "WMI Classes"
    Text               = "WMI Classes"
    Size               = @{Height=100; Width=250}
    Location           = New-Object System.Drawing.Point(5,5)
    AutoCompleteSource = "ListItems"
    AutoCompleteMode   = "SuggestAppend"
}
$WmiClassList = @(
    'Win32_UserAccount'
    'Win32_Group'
    'Win32_OperatingSystem'
    'Win32_ComputerSystem'
    'Win32_QuickFixEngineering'
    'Win32_Process '
    'Win32_Service'
    'Win32_Product'
    'Win32_StartupCommand'
    'Win32_BaseBoard'
    'Win32_BIOS'
    'Win32_Processor'
    'Win32_LogicalDisk'
    'Win32_DiskDrive'
    'Win32_MappedLogicalDisk'
    'Win32_Systemdriver'
    'Win32_PhysicalMemoryArray'
    'Win32_PhysicalMemory'
    'Win32_Share'
    'Win32_NetworkAdapterConfiguration'
    'Win32_NetworkLoginProfile'
    'Win32_Environment'
    'Win32_PnPEntity'
    'Win32_USBControllerDevice'
)
ForEach ($Class in $WmiClassList) {$WmiCommands.Items.Add($Class)}
$form.Controls.Add($WmiCommands)

$ComputerName = New-Object System.Windows.Forms.TextBox -Property @{
    Name      = "Computer"
    Text      = "Enter Computers (Comma Separated)"
    Size      = @{Height=80; Width=250}
    Location  = New-Object System.Drawing.Point(5,30)
    Multiline = $true
}
$form.Controls.Add($ComputerName)


$OKButton = New-Object Windows.Forms.Button -Property @{
    Size         = New-Object Drawing.Size 75, 25
    Location     = New-Object Drawing.Point 100, 115
    Text         = 'OK'
    DialogResult = [Windows.Forms.DialogResult]::OK
}
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)

$CancelButton = New-Object Windows.Forms.Button -Property @{
    Size         = New-Object Drawing.Size 75, 25
    Location     = New-Object Drawing.Point 180, 115
    Text         = 'Cancel'
    DialogResult = [Windows.Forms.DialogResult]::Cancel
}
$form.CancelButton = $CancelButton
$form.Controls.Add($CancelButton)

function Run-Form {
    $result = $form.ShowDialog()
    if ($result -eq [Windows.Forms.DialogResult]::OK) {
        $results = foreach ($Computer in $($computername.text -split ', ' -split ',' -split ' ')) {
            Get-WmiObject -Class $($WmiCommands.SelectedItem) -ComputerName $Computer | Select-Object -ExcludeProperty _* 
        }
        $results | Out-GridView -Title $WmiCommands.SelectedItem
        Run-Form
    }
    
}
Run-Form


