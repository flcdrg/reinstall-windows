# Things to install/run as the signed-in user, but not elevated

# Install Azure Artifacts credential provider
Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-artifacts-credprovider.ps1) } -AddNetfx"

# NuGet global package cache - https://learn.microsoft.com/en-us/nuget/consume-packages/managing-the-global-packages-and-cache-folders?WT.mc_id=DOP-MVP-5001655
[Environment]::SetEnvironmentVariable("NUGET_PACKAGES", "d:\packages", [System.EnvironmentVariableTarget]::User)

# pnpm global store - https://pnpm.io/cli/store
[Environment]::SetEnvironmentVariable("PNPM_HOME", "D:\pnpm-store\", [System.EnvironmentVariableTarget]::User)

# Create Firefox profile (so we can then set prefs)
& 'C:\Program Files\Mozilla Firefox\firefox.exe' --headless --screenshot nul

$firefoxProfile = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles" | Where-Object { $_.Name -match "default-release" } | Select-Object -First 1

# TODO confirm this is the right place to copy prefs.js to

# Git configuration

git config --global core.editor "code --wait"
git config --global fetch.prune true
git config --global push.autoSetupRemote true
git config --global user.email "david@gardiner.net.au"
git config --global user.name "David Gardiner"
git config --global init.defaultbranch "main"

# Enable Clipboard History
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Clipboard" -Name "EnableClipboardHistory" -Type DWord -Value 1 -Force