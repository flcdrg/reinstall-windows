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

if (Test-Path 'd:\choco-cache') {
    choco config set --name="'cacheLocation'" --value="'d:\packages\choco-cache'"
}

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

[Net.ServicePointManager]::SecurityProtocol =
    [Net.ServicePointManager]::SecurityProtocol -bor
    [Net.SecurityProtocolType]::Tls12

# This will install NuGet module if missing
Get-PackageProvider -Name NuGet -ForceBootstrap

# PowerShellGet. Do this early as reboots are required
if (-not (Get-InstalledModule -Name PowerShellGet -ErrorAction SilentlyContinue)) {
    Write-Host "Install-Module PowerShellGet"
    Install-Module -Name "PowerShellGet" -AllowClobber -Force -Scope AllUsers

    # Exit equivalent
    Invoke-Reboot
}

# Write-Host "Set-PSRepository"
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module Microsoft.PowerShell.PSResourceGet -Repository PSGallery -Scope AllUsers

# This should mitigate 'Cannot retrieve the dynamic parameters for the cmdlet. Loading repository store failed' error?
Get-PSResourceRepository
Set-PSResourceRepository PSGallery -Trusted

# Some things are now installed/configured via Windows Image autounattend.xml now

Write-Host "Installing packages"

# Disable VirusTotal checking (as we seem to hit a threshold otherwise)
choco feature disable --name=virusCheck

Write-Host "Temp: $($env:temp)"

choco install firefox  --params "/NoDesktopShortcut"
choco pin add -n=firefox

choco install 7zip
choco install audacity
choco install azure-cli
choco install azure-functions-core-tools --params "'/x64'"
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

choco install fnm # Use this instead of nvm (partly because of https://github.com/coreybutler/nvm-windows/issues/1068)
if (-not(Get-Command node -ErrorAction Ignore)) {
    fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
    
    fnm install --lts
    fnm use lts-latest
}

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

choco install nerd-fonts-CascadiaCode
choco install nerd-fonts-FiraCode

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
# choco install visualstudio2022enterprise --svc --package-parameters "'--add Microsoft.VisualStudio.Workload.Azure --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb --add Microsoft.VisualStudio.Workload.VisualStudioExtension --includeRecommended --remove Microsoft.VisualStudio.Component.Azure.Powershell'"
# choco pin add -n="visualstudio2022enterprise"
choco install visualstudio2026enterprise-preview --pre --svc --package-parameters "'--add Microsoft.VisualStudio.Workload.Azure --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb --add Microsoft.VisualStudio.Workload.VisualStudioExtension --includeRecommended --remove Microsoft.VisualStudio.Component.Azure.Powershell'"
choco pin add -n="visualstudio2026enterprise-preview"

# After Visual Studio
choco install dotUltimate --svc  --params "'/NoCpp /NoTeamCityAddin'"
choco install nuget.commandline

# Install after other packages, so integration will work
choco install beyondcompare
choco install beyondcompare-integration

choco install docker-desktop

Update-ExecutionPolicy RemoteSigned
Set-WindowsExplorerOptions -EnableShowFileExtensions -EnableExpandToOpenFolder

# Don't install any Azure CLI extension in Boxstarter, as they will be installed with admin permissions in the user's profile (and then fail to work as a regular user)
# az extension add --name azure-devops

# Remove pre-installed Pester Module
if (Test-Path "C:\Program Files\WindowsPowerShell\Modules\Pester\3.4.0" ) {
    $module = "C:\Program Files\WindowsPowerShell\Modules\Pester"
    takeown /F $module /A /R
    icacls $module /reset
    icacls $module /grant "*S-1-5-32-544:F" /inheritance:d /T
    Remove-Item -Path $module -Recurse -Force -Confirm:$false
}

$psmodules = @(Get-PSResource -Scope AllUsers | Select-Object -ExpandProperty Name)

$modulesToInstall = "Terminal-Icons", "posh-git", "PolicyFileEditor", "Pester"

$modulesToInstall | Foreach-Object {
    if ($psmodules -notcontains $_) {
        Write-Host "Installing $_"
        Install-PSResource -Name $_ -Scope AllUsers
    }
}

# wsl doesn't set exit code on failure.
$wslstatus = wsl --status 2>&1
if ($wslstatus -eq "Default Version: 2" ) {
    wsl --install -d Ubuntu --no-launch
}

# Avoid clash with builtin function
Boxstarter.WinConfig\Install-WindowsUpdate -getUpdatesFromMS -acceptEula

Enable-UAC

# Restore VirusTotal
choco feature enable --name=virusCheck