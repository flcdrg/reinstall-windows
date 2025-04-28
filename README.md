# Reinstall Windows

Many of these scripts were originally located in <https://gist.github.com/flcdrg>. Newer versions will live here so they can be better version controlled.

## Manual steps

1. Deactivate any licensed software that is linked to the machine (eg. Red Gate)
2. Shutdown any VMs

## Scripts relating to installing/reinstalling Windows

- [post-install.ps1](post-install.ps1) - Things to run after Windows installation (run with elevated permissions)
- [post-install-nonadmin.ps1](post-install-nonadmin.ps1) - Things to run after Windows installation (run with non-elevated permissions)
- [Set-Touchpad.ps1](Set-Touchpad.ps1) - Disable single tap to click with Touchpad

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

Download [latest driver pack](https://www.dell.com/support/kbdoc/en-au/000214839/xps-15-9530-windows-11-driver-pack) and put in this directory

```powershell
mkdir packages\Other\SafeOSDynamic
```

```powershell
mkdir packages\Other\SetupDynamic
```

```powershell
mkdir packages\OtherDrivers
```

Create a subdirectory for each additional driver from hardware vendor or Microsoft Update Catalog. (Use the UpdateID for a constant URL) and save .cab file or actual driver files. Cab will be automatically extracted by script.

- [Goodix - Biometric - 3.4.39.480](https://www.catalog.update.microsoft.com/Search.aspx?q=0306ef03-48fe-4088-b87f-ecfd3013229e)
- [Microsoft - Image - 5.20.102.0](https://www.catalog.update.microsoft.com/Search.aspx?q=cb930838-93d4-4d89-96de-0712f579c6af)
- [Surface - Keyboard - 1.0.104.0](https://www.catalog.update.microsoft.com/Search.aspx?q=e02c0250-52da-4b93-b42f-e2a05dbb8069)