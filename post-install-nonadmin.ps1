# Things to install/run as the signed-in user, but not elevated

# Install Azure Artifacts credential provider
Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-artifacts-credprovider.ps1) } -AddNetfx"

# Use DevDrive for package caches - https://learn.microsoft.com/en-us/windows/dev-drive/#storing-package-cache-on-dev-drive
# NuGet global package cache - https://learn.microsoft.com/en-us/nuget/consume-packages/managing-the-global-packages-and-cache-folders?WT.mc_id=DOP-MVP-5001655
[Environment]::SetEnvironmentVariable("NUGET_PACKAGES", "d:\packages\nuget", [System.EnvironmentVariableTarget]::User)

# pnpm global store - https://pnpm.io/cli/store
[Environment]::SetEnvironmentVariable("PNPM_HOME", "D:\packages\pnpm-store\", [System.EnvironmentVariableTarget]::User)

# Add pnpm global store to path (to support global packages)
./Set-PathVariable.ps1 -NewLocation "D:\packages\pnpm-store\"

# Python UV cache
[Environment]::SetEnvironmentVariable("UV_CACHE_DIR", "D:\packages\uv-cache\", [System.EnvironmentVariableTarget]::User)

# Gradle (Java)
[Environment]::SetEnvironmentVariable("GRADLE_USER_HOME", "d:\packages\.gradle", [System.EnvironmentVariableTarget]::User)

# Symbols
[Environment]::SetEnvironmentVariable("_NT_SYMBOL_PATH", "srv*d:\packages\symbols*https://msdl.microsoft.com/download/symbols", [System.EnvironmentVariableTarget]::User)

# Tell Corepack not to automatically add packageManager to package.json files (https://blog.hyperknot.com/p/corepacks-packagemanager-field)
[Environment]::SetEnvironmentVariable("COREPACK_ENABLE_AUTO_PIN", "0", [System.EnvironmentVariableTarget]::User)

# Enable Clipboard History
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Clipboard" -Name "EnableClipboardHistory" -Type DWord -Value 1 -Force

# Create .zip file that includes all BC*.xml files
Compress-Archive -Path "BC*.xml" -DestinationPath "BCSettings.bcpkg" -Force
& "$($env:ProgramFiles)\Beyond Compare 5\BComp.com" .\BCSettings.bcpkg /silent
