# PowerShell modules. Run this from elevated PowerShell 7

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