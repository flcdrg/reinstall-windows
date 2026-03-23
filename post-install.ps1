# PowerShell modules. Run this from elevated PowerShell 7
# Equivalent code from this file is embedded in the autounattend.xml (as part of the FirstLogon scripts)

# Remove preinstalled Pester
$module = "C:\Program Files\WindowsPowerShell\Modules\Pester"
takeown /F $module /A /R
icacls $module /reset
icacls $module /grant "*S-1-5-32-544:F" /inheritance:d /T
Remove-Item -Path $module -Recurse -Force -Confirm:$false

# Modules
Install-Module -Scope AllUsers posh-git
Install-Module -Scope AllUsers Terminal-Icons
Install-module -scope allusers Az
Install-Module -Scope AllUsers -Name Pester -Force

# Remove AzureRM by uninstalling "Microsoft Azure PowerShell - Month Year"

# WSL2 on Windows 11
wsl --install

# Uninstall Boxstarter temporary package (update package name as appropriate)
choco uninstall tmp3E2.tmp --skip-autouninstaller --skip-powershell

# Chocolatey
choco config set --name="'defaultPushSource'" --value="'https://push.chocolatey.org/'"

# Re-Trust Dev Drive - https://learn.microsoft.com/windows/dev-drive/?WT.mc_id=DOP-MVP-5001655#how-do-i-designate-a-dev-drive-as-trusted
fsutil devdrv trust D:

# Re-enable Windows Spotlight (https://github.com/cschneegans/unattend-generator/issues/222)
reg.exe add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableCloudOptimizedContent" /t REG_DWORD /d 1 /f

# Make local ethernet connections private
Get-NetConnectionProfile -InterfaceAlias 'Ethernet*' | Set-NetConnectionProfile -NetworkCategory 'Private';