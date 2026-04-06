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