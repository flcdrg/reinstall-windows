# Create Firefox profile (so we can then set prefs)
& 'C:\Program Files\Mozilla Firefox\firefox.exe' --headless --screenshot nul

$firefoxProfile = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles" | Where-Object { $_.Name -match "default-release" } | Select-Object -First 1
Copy-Item .\prefs.js -Destination $($firefoxProfile.FullName)\user.js

# Git configuration

# git config --global core.editor "code --wait"
# git config --global fetch.prune true
# git config --global push.autoSetupRemote true
# git config --global user.email "david@gardiner.net.au"
# git config --global user.name "David Gardiner"
# git config --global init.defaultbranch "main"
Copy-Item $env:OneDrive\Desktop\.gitconfig* $env:USERPROFILE\

# Windows Terminal
Copy-Item .\settings.json $Env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\


