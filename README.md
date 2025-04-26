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
