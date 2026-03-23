# Create Firefox profile (so we can then set prefs)
& 'C:\Program Files\Mozilla Firefox\firefox.exe' -CreateProfile david

$firefoxProfile = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles" | Where-Object { $_.Name -like "*.david" } | Select-Object -First 1
Copy-Item .\prefs.js -Destination "$($firefoxProfile.FullName)\user.js"

# Git configuration

<#
git config --global core.editor "code --wait"
git config --global fetch.prune true
git config --global push.autoSetupRemote true
git config --global user.email "david@gardinerfamily.au"
git config --global user.name "David Gardiner"
git config --global init.defaultbranch "main"
git config --global --add --bool rebase.updateRefs true
#>

# Git configs from OneDrive
Copy-Item $env:OneDrive\Desktop\.gitconfig* $env:USERPROFILE\

# Windows Terminal
Copy-Item .\settings.json $Env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\

# Set default Downloads folder to D:\downloads
New-Item -ItemType Directory -Path "D:\downloads" -Force | Out-Null
$userShellFoldersPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
$shellFoldersPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
Set-ItemProperty -Path $userShellFoldersPath -Name "{374DE290-123F-4565-9164-39C4925E467B}" -Value "D:\downloads"
Set-ItemProperty -Path $shellFoldersPath -Name "Downloads" -Value "D:\downloads"


if (-not(Get-Command node -ErrorAction Ignore)) {
    fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
    
    fnm install --lts
    fnm use lts-latest
}