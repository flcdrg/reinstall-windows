# Reinstall Windows

Many of these scripts were originally located in <https://gist.github.com/flcdrg>. Newer versions will live here so they can be better version controlled.

## Manual steps

1. Deactivate any licensed software that is linked to the machine (eg. Red Gate)
2. Shutdown any VMs
3. Ensure that Bitlocker recovery keys are all backed up.

## autounattend.xml

<https://schneegans.de/windows/unattend-generator/>

Includes assumption that C: is partition 3 of disk 0

eg.

```text
DISKPART> list part

  Partition ###  Type              Size     Offset
  -------------  ----------------  -------  -------
  Partition 1    System             100 MB  1024 KB
  Partition 2    Reserved            16 MB   101 MB
  Partition 3    Primary           1168 GB   117 MB
```

## Scripts relating to installing/reinstalling Windows

- [post-install.ps1](post-install.ps1) - Things to run after Windows installation (run with elevated permissions)
- [post-install-nonadmin.ps1](post-install-nonadmin.ps1) - Things to run after Windows installation (run with non-elevated permissions)
- [Set-Touchpad.ps1](Set-Touchpad.ps1) - Disable single tap to click with Touchpad

## Package caches

<https://learn.microsoft.com/en-us/windows/dev-drive/#storing-package-cache-on-dev-drive>

## Firefox

[prefs.js](prefs.js)

## Windows Terminal

Copy to `$Env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`

[settings.json](settings.json)

## Mount VHD for DevDrive backup

Windows schedule tasks:

- [Mount_20VHD.xml](Mount_20VHD.xml)
- [Run_20Robocopy.xml](Run_20Robocopy.xml)

## Windows image updates

- [update.ps1](update.ps1)

Prerequisites:

```powershell
mkdir oldMedia\Ge\client_professional_en-us
```

And download Windows ISO, mount and copy files into that directory.

```powershell
mkdir packages\CU
```

Download latest cumulative update(s) and put in this directory

```powershell
mkdir packages\DeployDriverPack
```

Download [latest driver pack](https://www.dell.com/support/kbdoc/en-au/000214839/xps-15-9530-windows-11-driver-pack) and put in this directory, then run to to extract all files.

```powershell
.\packages\DeployDriverPack\XPS-15-9530-VV12J_Win11_1.0_A12.exe /s /e=D:\git\reinstall-windows\packages\DeployDriverPack
```

### Dynamic updates

Create the following directories:

```powershell
mkdir packages\Other\SafeOSDynamic
mkdir packages\Other\SetupDynamic
mkdir packages\OtherDrivers
```

<https://learn.microsoft.com/en-us/windows/deployment/update/media-dynamic-update#windows-11-version-22h2-and-later-dynamic-update-packages>

Mostly these can be ignored as now Microsoft are releasing new ISOs each month with all patches.

### Capture drivers

(From elevated)
```powershell
Export-WindowsDriver -Online -Destination D:\git\reinstall-windows\packages\OtherDrivers\
```

Use the most recent version of each. There isn't always a new release every month.

Download the latest x64 files

The cumulative update may include a servicing stack update. You'll need to refer to the support article to figure out which file is the CU and which is the SSU. If it doesn't, then just point to the same msu

.NET Cumulative updates

1. Go to <https://learn.microsoft.com/en-us/dotnet/framework/release-notes/release-notes>
2. Select latest cumulative update
3. Click on link under **Summary tables** to go to the support article, making sure it applies to your Windows release.
4. Under **How to get this update**, locate the **Microsoft Update Catalog** row and click on the link
5. Save files to `packages\Other`

Create a subdirectory for each additional driver from hardware vendor or Microsoft Update Catalog. (Use the UpdateID for a constant URL) and save .cab file or actual driver files. Cab will be automatically extracted by script.

From elevated prompt:

Mount ISO - 

```powershell
Mount-DiskImage -ImagePath D:\git\reinstall-windows\en-us_windows_11_consumer_editions_version_25h2_updated_march_2026_x64_dvd_a1cf6c36.iso
```

Copy entire contents of ISO to D:\git\reinstall-windows\oldMedia\Ge\client_professional_en-us\

Remove existing install.wim

```powershell
rm .\oldMedia\Ge\client_professional_en-us\sources\install.wim
```

Extract just Windows 11 Pro image from ISO to local

```powershell
Export-WindowsImage -SourceImagePath G:\sources\install.wim -SourceIndex 6 -DestinationImagePath oldMedia\Ge\client_professional_en-us\sources\install.wim -CompressionType max
```

Unmount ISO

Ensure that Windows images are mounted on an NTFS volume (not ReFS/DevDrive), otherwise you'll get weird file access errors

Copy autounattend.xml to USB
Suspend Bitlocker 
Reboot machine
Press F12 to bring up boot menu
Select USB drive (second volume?)


After setup completes, run these scripts in order from an elevated PowerShell prompt:

1. Run [pre-boxstarter-admin.ps1](pre-boxstarter-admin.ps1)
2. Run [Boxstarter](boxstarter.ps1)
3. Run [post-boxstarter-admin.ps1](post-boxstarter-admin.ps1)

Run these scripts from a non-elevated PowerShell prompt:

1. Run [post-boxstarter-nonadmin.ps1](post-boxstarter-nonadmin.ps1)
