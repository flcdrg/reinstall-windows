# 1. Install Chocolatey
<#
Set-ExecutionPolicy RemoteSigned -Force

# Create empty profile (so profile-integration scripts have something to append to)
if (-not (Test-Path $PROFILE)) {
    $directory = [IO.Path]::GetDirectoryName($PROFILE)
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory $directory | Out-Null
    }

    "# Profile" > $PROFILE
}

iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco feature enable -n=allowGlobalConfirmation
choco feature enable -n=useRememberedArgumentsForUpgrades

cp $env:onedrive\private\chocolatey.license.xml .

choco install chocolatey.extension
choco install boxstarter

# DELL ONLY

On Dell machine, you may need to run the following to work around a bug in Waves services that cause a reboot loop (https://www.reddit.com/r/sysadmin/comments/10fas8x/intel_openvino_causing_daily_reboots_related_to/?rdt=48856)
## Stop and Disable Waves Audio Service

Set-Service -Name "WavesSysSvc" -Status Stopped -StartupType Disabled

## Clear registry key

Clear-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations

## Delete all temporary folders related to OpenVino

Remove-Item -Recurse -Force "C:\Program Files\Waves\IntelOpenVINO_*"
Remove-Item -Recurse -Force "C:\Program Files\Waves\IntelOpenVINO1*"

# END DELL ONLY
#>
# 2. Run with this:
<#
$cred=Get-Credential domain\username
Install-BoxstarterPackage -Credential $cred -PackageName https://gist.githubusercontent.com/flcdrg/87802af4c92527eb8a30/raw/1-boxstarter-bare-v4.ps1
#>

# Some things are now installed/configured via Windows Image autounattend.xml now

Write-Host "Installing packages"

# Disable VirusTotal checking (as we seem to hit a threshold otherwise)
#choco feature disable --name=virusCheck

Write-Host "Temp: $($env:temp)"

choco install firefox  --params "/NoDesktopShortcut"
choco pin add -n=firefox

choco install 7zip
choco install audacity
choco install azure-cli
choco install azure-functions-core-tools --params "'/x64'" --svc
choco install becyicongrabber
choco install bind-toolsonly
choco install cascadia-code-nerd-font

# This breaks Boxstarter - https://github.com/chocolatey/boxstarter/issues/560
# choco install chocolatey-community-validation.Extension

if ((get-wmiobject Win32_ComputerSystem).manufacturer -like "*Dell*") {
    choco install dellcommandupdate-uwp
}
choco install dotnet-6.0-sdk
choco install dotnet-8.0-sdk
choco install dotnet-9.0-sdk

choco install echoargs
choco install ffmpeg

choco install fnm # Use this instead of nvm (partly because of https://github.com/coreybutler/nvm-windows/issues/1068). Node installs can be done non-elevated


choco install gh
choco install git
choco install hwinfo
choco install imagemagick

if ((get-wmiobject Win32_ComputerSystem).manufacturer -like "*Lenovo*") {
    choco install lenovo-thinkvantage-system-update
}

choco install logioptionsplus
choco install microsoftazurestorageexplorer


choco install msbuild-structured-log-viewer
choco pin add -n=msbuild-structured-log-viewer

winget install "NuGet Package Explorer" --silent --accept-source-agreements --accept-package-agreements --disable-interactivity

choco install office365business  --params='/exclude:"Access Groove Lync OneDrive Outlook Publisher"'
choco pin add -n=office365business

choco install paint.net
choco pin add -n="paint.net"

choco install obs-studio

# https://learn.microsoft.com/en-gb/microsoft-365-apps/deploy/office-deployment-tool-configuration-options#id-attribute-part-of-excludeapp-element
choco install office365business --params "'/exclude:Access Bing Groove Lync OneDrive OneNote Outlook Publisher Teams '"
choco install oh-my-posh
choco install PDFXchangeEditor  --params '"/NoDesktopShortcuts /NoUpdater"'
# choco install python2  # Required by some NPM/Node packages (eg node-sass)
choco install powertoys # included mousewithout borders and zoomit
choco install oscar-cpap-analysis

# This will conflict with earlier font packages, so make sure it happens after a reboot
choco install FiraCode  # font

choco install pingplotter
choco install pnpm
choco install powershell-core

choco install rode-central
choco install rode-connect
choco install screentogif

choco install slack
choco install streamdeck

# install this with parameters manually
# choco install synology-activebackup-for-business-agent

choco install terraform
choco install terrascan
choco install tflint
choco install thunderbird
choco install tortoisegit

#choco install vagrant  # Not sure why, but Boxstarter gets in a loop thinking this fails with 3010 (which should be fine)
choco install vscode
choco pin add -n=vscode
choco pin add -n="vscode.install"
choco install vswhere
choco install vt-cli

choco install windirstat

choco install zoom
choco pin add -n="zoom"

# SSMS installer includes azure data studio
choco install sql-server-management-studio --svc

# Visual Studio 2022 (Ignore virus scanning as sometimes the catalog file it downloads hasn't been scanned)
# could add --passive package parameter if you want to see the installer UI for progress
# don't install Microsoft.VisualStudio.Component.Azure.Powershell as that's the old AzureRM PowerShell bits
choco install visualstudio2022enterprise --svc --package-parameters "'--add Microsoft.VisualStudio.Workload.Azure --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb --add Microsoft.VisualStudio.Workload.VisualStudioExtension --includeRecommended --remove Microsoft.VisualStudio.Component.Azure.Powershell --path cache=D:\VS\Cache'"
choco pin add -n="visualstudio2022enterprise"
# choco install visualstudio2022enterprise-preview --pre --svc --package-parameters "'--add Microsoft.VisualStudio.Workload.Azure --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb --add Microsoft.VisualStudio.Workload.VisualStudioExtension --includeRecommended --remove Microsoft.VisualStudio.Component.Azure.Powershell'"
# choco pin add -n="visualstudio2022enterprise-preview"

# After Visual Studio
choco install dotUltimate --svc  --params "'/NoCpp /NoTeamCityAddin'"
choco install nuget.commandline

# Install after other packages, so integration will work
choco install beyondcompare
choco install beyondcompare-integration

choco install docker-desktop

Update-ExecutionPolicy RemoteSigned
Set-WindowsExplorerOptions -EnableShowFileExtensions -EnableExpandToOpenFolder

# Avoid clash with builtin function
Boxstarter.WinConfig\Install-WindowsUpdate -getUpdatesFromMS -acceptEula

# Enable updates from other Microsoft products
Set-ItemProperty -Path hklm:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings -Name AllowMUUpdateService -Value 1 -Type DWord

Enable-UAC

# Restore VirusTotal
#choco feature enable --name=virusCheck