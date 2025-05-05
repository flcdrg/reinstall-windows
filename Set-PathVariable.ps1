# Based on https://stackoverflow.com/a/39959060/25702, but adapted to change user-level environment variables.

<#
.SYNOPSIS
    Add a new location to the user path variable
.PARAMETER NewLocation
    The new location to add to the path variable.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
 param(
     [parameter(Mandatory=$true)]
     [string]$NewLocation)

 Begin
 {
     $regPath = "Environment"
     $hklm = [Microsoft.Win32.Registry]::CurrentUser

     Function GetOldPath()
     {
         $regKey = $hklm.OpenSubKey($regPath, $FALSE)
         $envpath = $regKey.GetValue("Path", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
         return $envPath
     }
 }

 Process
 {
     # Win32API error codes
     $ERROR_SUCCESS = 0
     $ERROR_DUP_NAME = 34
     $ERROR_INVALID_DATA = 13

     $NewLocation = $NewLocation.Trim();

     If ($NewLocation -eq "" -or $NewLocation -eq $null)
     {
         Exit $ERROR_INVALID_DATA
     }

     [string]$oldPath = GetOldPath
     Write-Verbose "Old Path: $oldPath"

     # Check whether the new location is already in the path
     $parts = $oldPath.split(";")
     If ($parts -contains $NewLocation)
     {
         Write-Warning "The new location is already in the path"
         Exit $ERROR_DUP_NAME
     }

     # Build the new path, make sure we don't have double semicolons
     $newPath = $oldPath + ";" + $NewLocation
     $newPath = $newPath -replace ";;",""

     if ($pscmdlet.ShouldProcess("%Path%", "Add $NewLocation")){

         # Add to the current session
         $env:path += ";$NewLocation"

         # Save into registry
         $regKey = $hklm.OpenSubKey($regPath, $True)
         $regKey.SetValue("Path", $newPath, [Microsoft.Win32.RegistryValueKind]::ExpandString)
         Write-Output "The operation completed successfully."
     }

     Exit $ERROR_SUCCESS
 }