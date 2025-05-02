# Things to run after Boxstarter has completed, with elevated permissions

# Bitlocker
# OperatingSystem C:      1,168.93 FullyEncrypted         100        {Tpm, RecoveryPassword}              On
# Enable-BitLocker -MountPoint c: -EncryptionMethod XtsAes128 -TpmProtector -UsedSpaceOnly
# Add-BitLockerKeyProtector -MountPoint c -RecoveryPasswordProtector

# Fix file ownership on D: (Takes around 12 minutes)
Measure-Command { takeown /F D:\ /R /SKIPSL /D N > NUL }

<#
Configure Bitlocker using PowerShell, similar to how Windows UI does it

If I use the Windows 11 UI to enable Bitlocker, it prompts me to select one or more locations to backup the recovery key (eg. Azure AD account, Microsoft account, file, print).

Once complete, I can see the following if I run `Get-BitLockerVolume -MountPoint c`

```text
VolumeType      Mount CapacityGB VolumeStatus           Encryption KeyProtector              AutoUnlock Protection
                Point                                   Percentage                           Enabled    Status
----------      ----- ---------- ------------           ---------- ------------              ---------- ----------
OperatingSystem C:      1,168.93 FullyEncrypted         100        {Tpm, RecoveryPassword}              On
```

If I enable Bitlocker using a PowerShell cmdlet `Enable-BitLocker -MountPoint c: -EncryptionMethod XtsAes128 -TpmProtector -UsedSpaceOnly`

Then the result is that the KeyProtector is only `Tmp`.

I can see that there is an option to run [`Add-BitLockerKeyProtector`](https://learn.microsoft.com/en-au/powershell/module/bitlocker/add-bitlockerkeyprotector?view=windowsserver2025-ps&WT.mc_id=DOP-MVP-5001655) but if you specify `-RecoveryPasswordProtector` then it asks for a password


473264-100221-495330-519255-058069-253814-033363-298067
#>



%>

# Uninstall Boxstarter temp package
choco export

$xml = [xml] (Get-Content .\packages.config)
$tmpPackageName = $xml.packages.package | Where-Object { $_.id.StartsWith("tmp") } | Select-Object -First 1 -ExpandProperty id
choco uninstall $tmpPackageName --skip-autouninstaller --skip-powershell

Remove-Item .\packages.config

# Enable-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-Management-PowerShell -Online -All

$vhdPath = "C:\Drives\DevDriveBackup.vhd"

New-VHD -Path $vhdPath -Dynamic -SizeBytes 300000000000 |
Mount-VHD -Passthru |
    Initialize-Disk -PassThru |     
    New-Partition -AssignDriveLetter -UseMaximumSize | 
    Format-Volume -FileSystem NTFS -Confirm:$false -Force

Dismount-VHD -Path $vhdPath

# Create scheduled task to mount VHD on boot
$taskName = "Mount DevDrive Backup VHD"
$taskDescription = "Mount the Dev Drive backup VHD on system startup"
$action = New-ScheduledTaskAction -Execute "pwsh" -Argument "-c Mount-Vhd -Path $vhdPath"
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
$action = New-ScheduledTaskAction -Execute "robocopy" -Argument "d:\ e:\ /mir /xj /xd 'D:\System Volume Information\' 'D:\`$RECYCLE.BIN\' 'd:\.pnpm-store"
$trigger = New-ScheduledTaskTrigger -Weekly -At "4:00PM" -DaysOfWeek Friday

Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

Register-ScheduledTask -TaskName $taskName -Description $taskDescription -Action $action -Trigger $trigger -Principal $principal -Settings $settings

