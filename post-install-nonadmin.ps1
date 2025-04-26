# Things to install/run as the signed-in user, but not elevated

# Install Azure Artifacts credential provider
Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-artifacts-credprovider.ps1) } -AddNetfx"

# NuGet global package cache - https://learn.microsoft.com/en-us/nuget/consume-packages/managing-the-global-packages-and-cache-folders?WT.mc_id=DOP-MVP-5001655
[Environment]::SetEnvironmentVariable("NUGET_PACKAGES", "d:\packages", [System.EnvironmentVariableTarget]::User)

# pnpm global store - https://pnpm.io/cli/store
[Environment]::SetEnvironmentVariable("PNPM_HOME", "D:\pnpm-store\", [System.EnvironmentVariableTarget]::User)

# Enable Clipboard History
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Clipboard" -Name "EnableClipboardHistory" -Type DWord -Value 1 -Force