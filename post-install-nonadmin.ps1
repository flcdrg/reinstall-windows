# This script is embedded in the autounattend.xml as part of the UserOnce script.
# As such, it must not reference any other files/scripts.

# Based on https://stackoverflow.com/a/39959060/25702, but adapted to change user-level environment variables.

function Set-PathVariable {
    <#
    .SYNOPSIS
        Add a new location to the user path variable.
    .PARAMETER NewLocation
        The new location to add to the path variable.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$NewLocation
    )

    begin {
        function Build-NewPath {
            <#
            .SYNOPSIS
                Builds a new PATH string by appending a new location to an existing PATH value.
            .PARAMETER OldPath
                The existing PATH value.
            .PARAMETER NewLocation
                The new location to append.
            #>
            param(
                [string]$OldPath,
                [string]$NewLocation
            )

            # Build the new path, make sure we don't have consecutive semicolons or a leading semicolon.
            $newPath = $OldPath + ";" + $NewLocation
            $newPath = ($newPath -replace ";+", ";").TrimStart(";")

            return $newPath
        }

        $regPath = "Environment"
        $hklm = [Microsoft.Win32.Registry]::CurrentUser

        function GetOldPath {
            $regKey = $hklm.OpenSubKey($regPath, $false)
            $envPath = $regKey.GetValue("Path", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            return $envPath
        }
    }

    process {
        # Win32API error codes
        $ERROR_SUCCESS = 0
        $ERROR_DUP_NAME = 34
        $ERROR_INVALID_DATA = 13

        $NewLocation = $NewLocation.Trim()

        if ($NewLocation -eq "" -or $null -eq $NewLocation) {
            #return $ERROR_INVALID_DATA
            Write-Warning "The new location is empty or null"
            return
        }

        [string]$oldPath = GetOldPath
        Write-Verbose "Old Path: $oldPath"

        # Check whether the new location is already in the path
        $parts = $oldPath.Split(";")
        if ($parts -contains $NewLocation) {
            Write-Warning "The new location is already in the path"
            return
        }

        # Build the new path, make sure we don't have double semicolons
        $newPath = Build-NewPath -OldPath $oldPath -NewLocation $NewLocation

        if ($PSCmdlet.ShouldProcess("%Path%", "Add $NewLocation")) {
            # Add to the current session
            $env:path += ";$NewLocation"

            # Save into registry
            $regKey = $hklm.OpenSubKey($regPath, $true)
            $regKey.SetValue("Path", $newPath, [Microsoft.Win32.RegistryValueKind]::ExpandString)
            Write-Output "The operation completed successfully."
        }

        return
    }
}

# Things to install/run as the signed-in user, but not elevated

# Install Azure Artifacts credential provider
Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-artifacts-credprovider.ps1) } -AddNetfx"

if (-not (Test-Path "D:\packages")) {
    New-Item -ItemType Directory -Path "D:\packages" | Out-Null
}

# Use DevDrive for package caches - https://learn.microsoft.com/en-us/windows/dev-drive/#storing-package-cache-on-dev-drive
# NuGet global package cache - https://learn.microsoft.com/en-us/nuget/consume-packages/managing-the-global-packages-and-cache-folders?WT.mc_id=DOP-MVP-5001655
[Environment]::SetEnvironmentVariable("NUGET_PACKAGES", "d:\packages\nuget", [System.EnvironmentVariableTarget]::User)

# pnpm global store - https://pnpm.io/cli/store
[Environment]::SetEnvironmentVariable("PNPM_HOME", "D:\packages\pnpm-store\", [System.EnvironmentVariableTarget]::User)

# Add pnpm global store to PATH (to support global packages)
Set-PathVariable -NewLocation "D:\packages\pnpm-store"

# NPM cache
[Environment]::SetEnvironmentVariable("npm_config_cache", "D:\packages\npm-cache\", [System.EnvironmentVariableTarget]::User)

# VCPkg cache
[Environment]::SetEnvironmentVariable("VCPKG_DEFAULT_BINARY_CACHE", "D:\packages\vcpkg-downloads\", [System.EnvironmentVariableTarget]::User)
if (-not (Test-Path "D:\packages\vcpkg-downloads")) {
    New-Item -ItemType Directory -Path "D:\packages\vcpkg-downloads" | Out-Null
}

# Python PIP cache
[Environment]::SetEnvironmentVariable("PIP_CACHE_DIR", "D:\packages\pip-cache\", [System.EnvironmentVariableTarget]::User)

# Python UV cache
[Environment]::SetEnvironmentVariable("UV_CACHE_DIR", "D:\packages\uv-cache\", [System.EnvironmentVariableTarget]::User)

# Rust Cargo cache
[Environment]::SetEnvironmentVariable("CARGO_HOME", "D:\packages\cargo\", [System.EnvironmentVariableTarget]::User)

# Maven local repository
[Environment]::SetEnvironmentVariable("MAVEN_OPTS", "-Dmaven.repo.local=D:\packages\maven", [System.EnvironmentVariableTarget]::User)

# Gradle (Java)
[Environment]::SetEnvironmentVariable("GRADLE_USER_HOME", "d:\packages\.gradle", [System.EnvironmentVariableTarget]::User)

# Symbols
[Environment]::SetEnvironmentVariable("_NT_SYMBOL_PATH", "srv*d:\packages\symbols*https://msdl.microsoft.com/download/symbols", [System.EnvironmentVariableTarget]::User)

# Vagrant Home - https://developer.hashicorp.com/vagrant/docs/other/environmental-variables#vagrant_home
[Environment]::SetEnvironmentVariable("VAGRANT_HOME", "D:\packages\vagrant.d", [System.EnvironmentVariableTarget]::User)

# Android development
if (-not (Test-Path "D:\packages\Android\Sdk")) {
    New-Item -ItemType Directory -Path "D:\packages\Android\Sdk" | Out-Null
}
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "D:\packages\Android\Sdk", [System.EnvironmentVariableTarget]::User)

Set-PathVariable -NewLocation "%ANDROID_HOME%\platform-tools"
Set-PathVariable -NewLocation "%ANDROID_HOME%\emulator"

# Tell Corepack not to automatically add packageManager to package.json files (https://blog.hyperknot.com/p/corepacks-packagemanager-field)
[Environment]::SetEnvironmentVariable("COREPACK_ENABLE_AUTO_PIN", "0", [System.EnvironmentVariableTarget]::User)

# Enable Clipboard History
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Clipboard" -Name "EnableClipboardHistory" -Type DWord -Value 1 -Force

# Claude Code on Windows - https://code.claude.com/docs/en/changelog#2-1-111
[Environment]::SetEnvironmentVariable("CLAUDE_CODE_USE_POWERSHELL_TOOL", "1", [System.EnvironmentVariableTarget]::User)

# PNPM
pnpm config set store-dir D:\packages\pnpm-store\ --global
# Reinstall global packages
pnpm install -g --force