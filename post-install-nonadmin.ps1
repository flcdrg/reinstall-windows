# Things to install/run as the signed-in user, but not elevated

# Install Azure Artifacts credential provider
iex "& { $(irm https://aka.ms/install-artifacts-credprovider.ps1) } -AddNetfx"

# NuGet global package cache - https://learn.microsoft.com/en-us/nuget/consume-packages/managing-the-global-packages-and-cache-folders?WT.mc_id=DOP-MVP-5001655
[Environment]::SetEnvironmentVariable("NUGET_PACKAGES", "d:\packages", [System.EnvironmentVariableTarget]::User)

# Create Firefox profile (so we can then set prefs)
& 'C:\Program Files\Mozilla Firefox\firefox.exe' --headless --screenshot nul

# Git configuration

git config --global core.editor "code --wait"
git config --global fetch.prune true
git config --global push.autoSetupRemote true
git config --global user.email "david@gardiner.net.au"
git config --global user.name "David Gardiner"
git config --global init.defaultbranch "main"