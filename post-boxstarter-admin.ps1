# Things to run after Boxstarter has completed, with elevated permissions

# Uninstall Boxstarter temp package
choco export

$xml = [xml] (Get-Content .\packages.config)
$tmpPackageName = $xml.packages.package | Where-Object { $_.id.StartsWith("tmp") } | Select-Object -First 1 -ExpandProperty id
choco uninstall $tmpPackageName --skip-autouninstaller --skip-powershell

Remove-Item .\packages.config

# Enable-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-Management-PowerShell -Online -All

# Create a VHD for backup, and a scheduled task to mount it on boot
$vhdPath = "C:\Drives\DevDriveBackup.vhd"

New-VHD -Path $vhdPath -Dynamic -SizeBytes 400000000000 |
Mount-VHD -Passthru |
    Initialize-Disk -PassThru |     
    New-Partition -DriveLetter 'E' -UseMaximumSize | 
    Format-Volume -FileSystem NTFS -Confirm:$false -Force

Dismount-VHD -Path $vhdPath

# Create scheduled task to mount VHD on boot
$taskName = "Mount DevDrive Backup VHD"
$taskDescription = "Mount the Dev Drive backup VHD on system startup"
$mountVhdCommand = "`$disk = Mount-Vhd -Path '$vhdPath' -Passthru | Get-Disk; `$partition = `$disk | Get-Partition | Select-Object -First 1; if (`$partition.DriveLetter -and `$partition.DriveLetter -ne 'E') { Set-Partition -DriveLetter `$partition.DriveLetter -NewDriveLetter 'E' }; if (-not `$partition.DriveLetter) { Add-PartitionAccessPath -DiskNumber `$partition.DiskNumber -PartitionNumber `$partition.PartitionNumber -AccessPath 'E:\' }"
$action = New-ScheduledTaskAction -Execute "pwsh" -Argument "-c $mountVhdCommand"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest 
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable

# Remove the task if it already exists
Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

# Register the new task
Register-ScheduledTask -TaskName $taskName -Description $taskDescription -Action $action -Trigger $trigger -Principal $principal -Settings $settings

# and a scheduled task to run Robocopy
$taskName = "Backup Dev Drive"
$taskDescription = "Backup the Dev Drive to the backup VHD"
# /c robocopy d:\ e:\ /mir /xj /xf *.iso /xf backup.log /xd "d:\$RECYCLE.BIN" d:\packages d:\VS d:\symbols > d:\backup.log
$action = New-ScheduledTaskAction -Execute "cmd" -Argument "/c robocopy d:\ e:\ /mir /xj /xf *.iso /xf backup.log /xf *.wim /xd `"`$RECYCLE.BIN`" d:\packages d:\VS d:\git\chocolatey-test-environment\.vagrant d:\git\reinstall-windows\packages d:\git\aspire\artifacts d:\git\PowerToys\src\modules > d:\backup.log"
$trigger = New-ScheduledTaskTrigger -Weekly -At "4:00PM" -DaysOfWeek Friday

Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

Register-ScheduledTask -TaskName $taskName -Description $taskDescription -Action $action -Trigger $trigger -Principal $principal -Settings $settings

# Create .zip file that includes all BC*.xml files
Compress-Archive -Path "BC*.xml" -DestinationPath "BCSettings.bcpkg" -Force
& "$($env:ProgramFiles)\Beyond Compare 5\BComp.com" .\BCSettings.bcpkg /silent
