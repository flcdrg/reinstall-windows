#Requires -RunAsAdministrator

# From https://learn.microsoft.com/en-us/windows/deployment/update/media-dynamic-update#get-started

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-TS { return "{0:HH:mm:ss}" -f [DateTime]::Now }

function Get-FirstFilePath {
    param (
        [Parameter(Mandatory)]
        [string]$PathPattern
    )

    $file = Get-ChildItem -Path $PathPattern -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $file) {
        return $file.FullName
    }

    return $null
}

function Test-DirectoryHasFiles {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [string]$Filter = '*'
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    return $null -ne (Get-ChildItem -Path $Path -Recurse -File -Filter $Filter -ErrorAction SilentlyContinue | Select-Object -First 1)
}

Write-Output "$(Get-TS): Starting media refresh"

# Declare Dynamic Update packages. A dedicated folder is used for the latest cumulative update, and as needed
# checkpoint cumulative updates.

$LCU_PATH = Get-FirstFilePath "$PSScriptRoot\packages\CU\*.msu"

$SETUP_DU_PATH = Get-FirstFilePath "$PSScriptRoot\packages\Other\SetupDynamic\*.cab"
$SAFE_OS_DU_PATH = Get-FirstFilePath "$PSScriptRoot\packages\Other\SafeOSDynamic\*.cab"
$DOTNET_CU_PATH = Get-FirstFilePath "$PSScriptRoot\packages\Other\windows11.0-*-ndp481_*.msu"

$DRIVER_PATH = "$PSScriptRoot\packages\DeployDriverPack"
$DRIVER_ADDTIONAL_PATH = "$PSScriptRoot\packages\OtherDrivers"

# Declare media for FOD and LPs
#$FOD_ISO_PATH = "$PSScriptRoot\packages\mul_languages_and_optional_features_for_windows_11_version_24h2_x64_dvd_eb44bee0.iso"

# Array of Features On Demand for main OS
# This is optional to showcase where these are added
# $FOD = @(
#     #'XPS.Viewer~~~~0.0.1.0'
# )

# Array of Legacy Features for main OS
# This is optional to showcase where these are added
$OC = @(
    'Client-ProjFS',
    'TelnetClient',
    'VirtualMachinePlatform',
    'Microsoft-Windows-Subsystem-Linux',
    'Microsoft-Hyper-V-All',
    'Microsoft-RemoteDesktopConnection'
)

# Mount the Features on Demand ISO
# Write-Output "$(Get-TS): Mounting FOD ISO"
# $FOD_ISO_DRIVE_LETTER = (Mount-DiskImage -ImagePath $FOD_ISO_PATH -ErrorAction stop | Get-Volume).DriveLetter
# $FOD_PATH = $FOD_ISO_DRIVE_LETTER + ":\LanguagesAndOptionalFeatures"

# Declare language for showcasing adding optional localized components
# $LANG = ""
# $LANG_FONT_CAPABILITY = "jpan"

# Declare language related cabs
#$WINPE_OC_PATH = "$FOD_ISO_DRIVE_LETTER`:\Windows Preinstallation Environment\x64\WinPE_OCs"
#$WINPE_OC_LANG_PATH = "$WINPE_OC_PATH\$LANG"
#$WINPE_OC_LANG_CABS = Get-ChildItem $WINPE_OC_LANG_PATH -Name
#$WINPE_OC_LP_PATH = "$WINPE_OC_LANG_PATH\lp.cab"
#$WINPE_FONT_SUPPORT_PATH = "$WINPE_OC_PATH\WinPE-FontSupport-$LANG.cab"
#$WINPE_SPEECH_TTS_PATH = "$WINPE_OC_PATH\WinPE-Speech-TTS.cab"
#$WINPE_SPEECH_TTS_LANG_PATH = "$WINPE_OC_PATH\WinPE-Speech-TTS-$LANG.cab"
#$OS_LP_PATH = "$FOD_PATH\Microsoft-Windows-Client-Language-Pack_x64_$LANG.cab"

# Declare folders for mounted images and temp files
$MEDIA_OLD_PATH = "$PSScriptRoot\oldMedia\Ge\client_professional_en-us"
$MEDIA_NEW_PATH = "$PSScriptRoot\newMedia"

# This should not be a ReFS/DevDrive!
$WORKING_PATH = "c:\isotemp"
$MAIN_OS_MOUNT = "$WORKING_PATH\MainOSMount"
$WINRE_MOUNT = "$WORKING_PATH\WinREMount"
$WINPE_MOUNT = "$WORKING_PATH\WinPEMount"

# Remove old temp directories
if (Test-Path -Path $WORKING_PATH) {
    Write-Output "$(Get-TS): Removing old working path $WORKING_PATH"
    Remove-Item -Path $WORKING_PATH -Recurse -Force
}

# Create folders for mounting images and storing temporary files
New-Item -ItemType directory -Path $WORKING_PATH -ErrorAction Stop 
New-Item -ItemType directory -Path $MAIN_OS_MOUNT -ErrorAction stop 
New-Item -ItemType directory -Path $WINRE_MOUNT -ErrorAction stop 
New-Item -ItemType directory -Path $WINPE_MOUNT -ErrorAction stop 

# Keep the original media, make a copy of it for the new, updated media.
Write-Output "$(Get-TS): Copying original media to new media path"

robocopy $MEDIA_OLD_PATH $MEDIA_NEW_PATH /S #/XF install.wim

Get-ChildItem $MEDIA_NEW_PATH -Recurse install.wim

Get-ChildItem -Path $MEDIA_NEW_PATH -Recurse | Where-Object { -not $_.PSIsContainer -and $_.IsReadOnly } | ForEach-Object { $_.IsReadOnly = $false }

# Expand driver cabs
if (Test-DirectoryHasFiles -Path $DRIVER_ADDTIONAL_PATH -Filter '*.cab') {
    Get-ChildItem -Path $DRIVER_ADDTIONAL_PATH -Recurse -File -Filter '*.cab' | ForEach-Object { expand $_ -F:* "$($_.DirectoryName)" }
}
else {
    Write-Warning "$(Get-TS): Skipping driver CAB expansion from $DRIVER_ADDTIONAL_PATH (no .cab files found)"
}

try {

    # Get just image 6 (Pro)
    # Export-WindowsImage -SourceImagePath $MEDIA_OLD_PATH\sources\install.wim -SourceIndex 6 -DestinationImagePath $MEDIA_NEW_PATH\sources\install.wim

    #
    # Update each main OS Windows image including the Windows Recovery Environment (WinRE)
    #

    # Get the list of images contained within the main OS
    $WINOS_IMAGES = Get-WindowsImage -ImagePath $MEDIA_NEW_PATH"\sources\install.wim"

    # Just do 1st and 6th image (Home and Pro)
    #Foreach ($IMAGE in $WINOS_IMAGES[0, 5]) {
    $selectedImages = @($WINOS_IMAGES[0])
    Foreach ($IMAGE in $selectedImages) {

        # first mount the main OS image
        Write-Output "$(Get-TS): Mounting main OS, image index $($IMAGE.ImageIndex)"
        Mount-WindowsImage -ImagePath $MEDIA_NEW_PATH"\sources\install.wim" -Index $IMAGE.ImageIndex -Path $MAIN_OS_MOUNT -ErrorAction stop -Verbose -LogLevel WarningsInfo

        if ($IMAGE.ImageIndex -eq "1" -or $selectedImages.Count -eq 1) {

            #
            # update Windows Recovery Environment (WinRE) within this OS image
            #
            Copy-Item -Path $MAIN_OS_MOUNT"\windows\system32\recovery\winre.wim" -Destination $WORKING_PATH"\winre.wim" -Force -ErrorAction stop 
            Write-Output "$(Get-TS): Mounting WinRE"
            Mount-WindowsImage -ImagePath $WORKING_PATH"\winre.wim" -Index 1 -Path $WINRE_MOUNT -ErrorAction stop 

            # Add servicing stack update (Step 1 from the table)
            if ($LCU_PATH) {
                Write-Output "$(Get-TS): Adding package $LCU_PATH to WinRE"        
                try {
                    Add-WindowsPackage -Path $WINRE_MOUNT -PackagePath $LCU_PATH   
                }
                Catch {
                    $theError = $_
                    Write-Output "$(Get-TS): $theError"
        
                    if ($theError.Exception -like "*0x8007007e*") {
                        Write-Warning "$(Get-TS): Failed with error 0x8007007e. This failure is a known issue with combined cumulative update, we can ignore."
                    }
                    else {
                        Write-Warning "$(Get-TS): Failed to add $LCU_PATH to WinRE. Exit code: $($theError.Exception.HResult). This is a warning, but the cumulative update will not be added to WinRE, which may cause issues with future updates if the servicing stack in WinRE is too old."
                    }
                }
            }
            else {
                Write-Warning "$(Get-TS): Skipping WinRE cumulative update step (no .msu found under packages\CU)"
            }

            #
            # Optional: Add the language to recovery environment
            #
        
            # Install language cabs for each optional package installed
            # $WINRE_INSTALLED_OC = Get-WindowsPackage -Path $WINRE_MOUNT
            # if ($LANG -ne "") {
            #     # Install lp.cab cab
            #     Write-Output "$(Get-TS): Adding package $WINPE_OC_LP_PATH to WinRE"
            #     Add-WindowsPackage -Path $WINRE_MOUNT -PackagePath $WINPE_OC_LP_PATH -ErrorAction stop 

            #     Foreach ($PACKAGE in $WINRE_INSTALLED_OC) {
            #         if ( ($PACKAGE.PackageState -eq "Installed") -and ($PACKAGE.PackageName.startsWith("WinPE-")) -and ($PACKAGE.ReleaseType -eq "FeaturePack") ) {
            #             $INDEX = $PACKAGE.PackageName.IndexOf("-Package")
            #             if ($INDEX -ge 0) {
            #                 $OC_CAB = $PACKAGE.PackageName.Substring(0, $INDEX) + "_" + $LANG + ".cab"
            #                 if ($WINPE_OC_LANG_CABS.Contains($OC_CAB)) {
            #                     $OC_CAB_PATH = Join-Path $WINPE_OC_LANG_PATH $OC_CAB
            #                     Write-Output "$(Get-TS): Adding package $OC_CAB_PATH to WinRE"
            #                     Add-WindowsPackage -Path $WINRE_MOUNT -PackagePath $OC_CAB_PATH -ErrorAction stop   
            #                 }
            #             }
            #         }
            #     }

            #     # Add font support for the new language
            #     if ( (Test-Path -Path $WINPE_FONT_SUPPORT_PATH) ) {
            #         Write-Output "$(Get-TS): Adding package $WINPE_FONT_SUPPORT_PATH to WinRE"
            #         Add-WindowsPackage -Path $WINRE_MOUNT -PackagePath $WINPE_FONT_SUPPORT_PATH -ErrorAction stop 
            #     }

            #     # Add TTS support for the new language
            #     if (Test-Path -Path $WINPE_SPEECH_TTS_PATH) {
            #         if ( (Test-Path -Path $WINPE_SPEECH_TTS_LANG_PATH) ) {
            #             Write-Output "$(Get-TS): Adding package $WINPE_SPEECH_TTS_PATH to WinRE"
            #             Add-WindowsPackage -Path $WINRE_MOUNT -PackagePath $WINPE_SPEECH_TTS_PATH -ErrorAction stop 

            #             Write-Output "$(Get-TS): Adding package $WINPE_SPEECH_TTS_LANG_PATH to WinRE"
            #             Add-WindowsPackage -Path $WINRE_MOUNT -PackagePath $WINPE_SPEECH_TTS_LANG_PATH -ErrorAction stop 
            #         }
            #     }
            # }

            # Add Safe OS
            if ($SAFE_OS_DU_PATH) {
                Write-Output "$(Get-TS): Adding package $SAFE_OS_DU_PATH to WinRE"
                Add-WindowsPackage -Path $WINRE_MOUNT -PackagePath $SAFE_OS_DU_PATH -ErrorAction stop 
            }
            else {
                Write-Warning "$(Get-TS): Skipping Safe OS Dynamic Update step (no .cab found in packages\Other\SafeOSDynamic)"
            }

            # Perform image cleanup
            Write-Output "$(Get-TS): Performing image cleanup on WinRE"
            DISM /image:$WINRE_MOUNT /cleanup-image /StartComponentCleanup /ResetBase /Defer 
            if ($LastExitCode -ne 0) {
                throw "Error: Failed to perform image cleanup on WinRE. Exit code: $LastExitCode"
            }

            # Dismount
            Dismount-WindowsImage -Path $WINRE_MOUNT  -Save -ErrorAction stop 

            # Export
            Write-Output "$(Get-TS): Exporting image to $WORKING_PATH\winre.wim"
            Export-WindowsImage -SourceImagePath $WORKING_PATH"\winre.wim" -SourceIndex 1 -DestinationImagePath $WORKING_PATH"\winre2.wim" -ErrorAction stop 

        }
    
        Copy-Item -Path $WORKING_PATH"\winre2.wim" -Destination $MAIN_OS_MOUNT"\windows\system32\recovery\winre.wim" -Force -ErrorAction stop 
    
        #
        # update Main OS
        #

        # Add servicing stack update (Step 17 from the table). Unlike WinRE and WinPE, we don't need to check for error 0x8007007e
        if ($LCU_PATH) {
            Write-Output "$(Get-TS): Adding package $LCU_PATH to main OS, index $($IMAGE.ImageIndex)"
            Add-WindowsPackage -Path $MAIN_OS_MOUNT -PackagePath $LCU_PATH
        }
        else {
            Write-Warning "$(Get-TS): Skipping main OS cumulative update step, index $($IMAGE.ImageIndex) (no .msu found under packages\CU)"
        }

        # Optional: Add language to main OS and corresponding language experience Features on Demand
        # Write-Output "$(Get-TS): Adding package $OS_LP_PATH to main OS, index $($IMAGE.ImageIndex)"
        # Add-WindowsPackage -Path $MAIN_OS_MOUNT -PackagePath $OS_LP_PATH -ErrorAction stop

        # Write-Output "$(Get-TS): Adding language FOD: Language.Fonts.Jpan~~~und-JPAN~0.0.1.0 to main OS, index $($IMAGE.ImageIndex)"
        #     Add-WindowsCapability -Name "Language.Fonts.$LANG_FONT_CAPABILITY~~~und-$LANG_FONT_CAPABILITY~0.0.1.0" -Path $MAIN_OS_MOUNT -Source $FOD_PATH -ErrorAction stop 

        # if ($LANG -ne "") {

        #     Write-Output "$(Get-TS): Adding language FOD: Language.Basic~~~$LANG~0.0.1.0 to main OS, index $($IMAGE.ImageIndex)"
        #     Add-WindowsCapability -Name "Language.Basic~~~$LANG~0.0.1.0" -Path $MAIN_OS_MOUNT -Source $FOD_PATH -ErrorAction stop 

        #     Write-Output "$(Get-TS): Adding language FOD: Language.OCR~~~$LANG~0.0.1.0 to main OS, index $($IMAGE.ImageIndex)"
        #     Add-WindowsCapability -Name "Language.OCR~~~$LANG~0.0.1.0" -Path $MAIN_OS_MOUNT -Source $FOD_PATH -ErrorAction stop 

        #     Write-Output "$(Get-TS): Adding language FOD: Language.Handwriting~~~$LANG~0.0.1.0 to main OS, index $($IMAGE.ImageIndex)"
        #     Add-WindowsCapability -Name "Language.Handwriting~~~$LANG~0.0.1.0" -Path $MAIN_OS_MOUNT -Source $FOD_PATH -ErrorAction stop 

        #     Write-Output "$(Get-TS): Adding language FOD: Language.TextToSpeech~~~$LANG~0.0.1.0 to main OS, index $($IMAGE.ImageIndex)"
        #     Add-WindowsCapability -Name "Language.TextToSpeech~~~$LANG~0.0.1.0" -Path $MAIN_OS_MOUNT -Source $FOD_PATH -ErrorAction stop 

        #     Write-Output "$(Get-TS): Adding language FOD: Language.Speech~~~$LANG~0.0.1.0 to main OS, index $($IMAGE.ImageIndex)"
        #     Add-WindowsCapability -Name "Language.Speech~~~$LANG~0.0.1.0" -Path $MAIN_OS_MOUNT -Source $FOD_PATH -ErrorAction stop 

        # }

        # Optional: Add additional Features On Demand
        # For ( $index = 0; $index -lt $FOD.count; $index++) {
        #     #
        #     Write-Output "$(Get-TS): Adding $($FOD[$index]) to main OS, index $($IMAGE.ImageIndex)"
        #     Add-WindowsCapability -Name $($FOD[$index]) -Path $MAIN_OS_MOUNT -Source $FOD_PATH -ErrorAction stop 
        # }    
    
        # Optional: Add Legacy Features (not image 1, as 'home' doesn't have these)
        # if ($IMAGE.ImageIndex -eq "0") {
        #     Write-Output "$(Get-TS): Skipping optional components for image index $($IMAGE.ImageIndex)"
        # }
        # else {
        Write-Output "$(Get-TS): Adding optional components to main OS, index $($IMAGE.ImageIndex)"
        
        Enable-WindowsOptionalFeature -Path $MAIN_OS_MOUNT -FeatureName $OC

        # DISM /Image:$MAIN_OS_MOUNT /Enable-Feature /FeatureName:$($OC[$index]) /All 
        if ($LastExitCode -ne 0) {
            throw "Error: Failed to add $OC to main OS, index $($IMAGE.ImageIndex). Exit code: $LastExitCode"
        }
        #}

        # Drivers
        if (Test-DirectoryHasFiles -Path $DRIVER_PATH -Filter '*.inf') {
            Write-Output "$(Get-TS): Adding drivers from $DRIVER_PATH to main OS, index $($IMAGE.ImageIndex)"
            Add-WindowsDriver -Path $MAIN_OS_MOUNT -Driver $DRIVER_PATH -Recurse -ErrorAction stop
        }
        else {
            Write-Warning "$(Get-TS): Skipping driver injection from $DRIVER_PATH for main OS, index $($IMAGE.ImageIndex) (no .inf files found)"
        }

        if (Test-DirectoryHasFiles -Path $DRIVER_ADDTIONAL_PATH -Filter '*.inf') {
            Write-Output "$(Get-TS): Adding drivers from $DRIVER_ADDTIONAL_PATH to main OS, index $($IMAGE.ImageIndex)"
            Add-WindowsDriver -Path $MAIN_OS_MOUNT -Driver $DRIVER_ADDTIONAL_PATH -Recurse -ErrorAction stop
        }
        else {
            Write-Warning "$(Get-TS): Skipping driver injection from $DRIVER_ADDTIONAL_PATH for main OS, index $($IMAGE.ImageIndex) (no .inf files found)"
        }

        # Add latest cumulative update
        if ($LCU_PATH) {
            Write-Output "$(Get-TS): Adding package $LCU_PATH to main OS, index $($IMAGE.ImageIndex)"
            Add-WindowsPackage -Path $MAIN_OS_MOUNT -PackagePath $LCU_PATH -ErrorAction stop 
        }
        else {
            Write-Warning "$(Get-TS): Skipping main OS cumulative update (latest CU) step, index $($IMAGE.ImageIndex) (no .msu found under packages\CU)"
        }

        # Perform image cleanup. Some Optional Components might require the image to be booted, and thus 
        # image cleanup may fail. We'll catch and handle as a warning.
        Write-Output "$(Get-TS): Performing image cleanup on main OS, index $($IMAGE.ImageIndex)"
        DISM /image:$MAIN_OS_MOUNT /cleanup-image /StartComponentCleanup 
        if ($LastExitCode -ne 0) {
            if ($LastExitCode -eq -2146498554) {       
                # We hit 0x800F0806 CBS_E_PENDING. We will ignore this with a warning
                # This is likely due to legacy components being added that require online operations.
                Write-Warning "$(Get-TS): Failed to perform image cleanup on main OS, index $($IMAGE.ImageIndex). Exit code: $LastExitCode. The operation cannot be performed until pending servicing operations are completed. The image must be booted to complete the pending servicing operation."
            }
            else {
                throw "Error: Failed to perform image cleanup on main OS, index $($IMAGE.ImageIndex). Exit code: $LastExitCode"
            }
        }

        # Finally, we'll add .NET 3.5 and the .NET cumulative update
        # Write-Output "$(Get-TS): Adding NetFX3~~~~ to main OS, index $($IMAGE.ImageIndex)"
        # Add-WindowsCapability -Name "NetFX3~~~~" -Path $MAIN_OS_MOUNT -Source $FOD_PATH -ErrorAction stop 

        # Add .NET Cumulative Update
        if ($DOTNET_CU_PATH) {
            Write-Output "$(Get-TS): Adding package $DOTNET_CU_PATH to main OS, index $($IMAGE.ImageIndex)"
            Add-WindowsPackage -Path $MAIN_OS_MOUNT -PackagePath $DOTNET_CU_PATH -ErrorAction stop 
        }
        else {
            Write-Warning "$(Get-TS): Skipping .NET cumulative update step, index $($IMAGE.ImageIndex) (no matching NDP .msu found)"
        }

        # Dismount
        Dismount-WindowsImage -Path $MAIN_OS_MOUNT -Save -ErrorAction stop 

        # Export
        Write-Output "$(Get-TS): Exporting image to $WORKING_PATH\install2.wim"
        Export-WindowsImage -SourceImagePath $MEDIA_NEW_PATH"\sources\install.wim" -SourceIndex $IMAGE.ImageIndex -DestinationImagePath $WORKING_PATH"\install2.wim" -ErrorAction stop 
    }

    Move-Item -Path $WORKING_PATH"\install2.wim" -Destination $MEDIA_NEW_PATH"\sources\install.wim" -Force -ErrorAction stop 

    #
    # update Windows Preinstallation Environment (WinPE)
    #

    # Get the list of images contained within WinPE
    $WINPE_IMAGES = Get-WindowsImage -ImagePath $MEDIA_NEW_PATH"\sources\boot.wim"

    Foreach ($IMAGE in $WINPE_IMAGES) {

        # update WinPE
        Write-Output "$(Get-TS): Mounting WinPE, image index $($IMAGE.ImageIndex)"
        Mount-WindowsImage -ImagePath $MEDIA_NEW_PATH"\sources\boot.wim" -Index $IMAGE.ImageIndex -Path $WINPE_MOUNT -ErrorAction stop 

        # Add servicing stack update (Step 9 from the table)
        try {
            if ($LCU_PATH) {
                Write-Output "$(Get-TS): Adding package $LCU_PATH to WinPE, image index $($IMAGE.ImageIndex)"
                Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $LCU_PATH
            }
            else {
                Write-Warning "$(Get-TS): Skipping WinPE cumulative update step, image index $($IMAGE.ImageIndex) (no .msu found under packages\CU)"
            }
        }
        Catch {
            $theError = $_
            Write-Output "$(Get-TS): $theError"
            if ($theError.Exception -like "*0x8007007e*") {
                Write-Warning "$(Get-TS): Failed with error 0x8007007e. This failure is a known issue with combined cumulative update, we can ignore."
            }
            else {
                throw
            }
        }

        # Install lp.cab cab
        # Write-Output "$(Get-TS): Adding package $WINPE_OC_LP_PATH to WinPE, image index $($IMAGE.ImageIndex)"
        # Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $WINPE_OC_LP_PATH -ErrorAction stop 

        # # Install language cabs for each optional package installed
        # $WINPE_INSTALLED_OC = Get-WindowsPackage -Path $WINPE_MOUNT
        # if ($LANG -ne "") {
        #     Foreach ($PACKAGE in $WINPE_INSTALLED_OC) {
        #         if ( ($PACKAGE.PackageState -eq "Installed") -and ($PACKAGE.PackageName.startsWith("WinPE-")) -and ($PACKAGE.ReleaseType -eq "FeaturePack") ) {
        #             $INDEX = $PACKAGE.PackageName.IndexOf("-Package")
        #             if ($INDEX -ge 0) {
        #                 $OC_CAB = $PACKAGE.PackageName.Substring(0, $INDEX) + "_" + $LANG + ".cab"
        #                 if ($WINPE_OC_LANG_CABS.Contains($OC_CAB)) {
        #                     $OC_CAB_PATH = Join-Path $WINPE_OC_LANG_PATH $OC_CAB
        #                     Write-Output "$(Get-TS): Adding package $OC_CAB_PATH to WinPE, image index $($IMAGE.ImageIndex)"
        #                     Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $OC_CAB_PATH -ErrorAction stop   
        #                 }
        #             }
        #         }
        #     }
        # }


        # Add font support for the new language
        # if ( (Test-Path -Path $WINPE_FONT_SUPPORT_PATH) ) {
        #     Write-Output "$(Get-TS): Adding package $WINPE_FONT_SUPPORT_PATH to WinPE, image index $($IMAGE.ImageIndex)"
        #     Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $WINPE_FONT_SUPPORT_PATH -ErrorAction stop 
        # }

        # Add TTS support for the new language
        # if (Test-Path -Path $WINPE_SPEECH_TTS_PATH) {
        #     if ( (Test-Path -Path $WINPE_SPEECH_TTS_LANG_PATH) ) {
        #         Write-Output "$(Get-TS): Adding package $WINPE_SPEECH_TTS_PATH to WinPE, image index $($IMAGE.ImageIndex)"
        #         Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $WINPE_SPEECH_TTS_PATH -ErrorAction stop 

        #         Write-Output "$(Get-TS): Adding package $WINPE_SPEECH_TTS_LANG_PATH to WinPE, image index $($IMAGE.ImageIndex)"
        #         Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $WINPE_SPEECH_TTS_LANG_PATH -ErrorAction stop 
        #     }
        # }

        # # Generates a new Lang.ini file which is used to define the language packs inside the image
        # if ( (Test-Path -Path $WINPE_MOUNT"\sources\lang.ini") ) {
        #     Write-Output "$(Get-TS): Updating lang.ini"
        #     DISM /image:$WINPE_MOUNT /Gen-LangINI /distribution:$WINPE_MOUNT 
        #     if ($LastExitCode -ne 0) {
        #         throw "Error: Failed to update lang.ini. Exit code: $LastExitCode"
        #     }
        # }

        # Add latest cumulative update
        if ($LCU_PATH) {
            Write-Output "$(Get-TS): Adding package $LCU_PATH to WinPE, image index $($IMAGE.ImageIndex)"
            Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $LCU_PATH -ErrorAction stop 
        }
        else {
            Write-Warning "$(Get-TS): Skipping WinPE latest cumulative update step, image index $($IMAGE.ImageIndex) (no .msu found under packages\CU)"
        }

        # Perform image cleanup
        Write-Output "$(Get-TS): Performing image cleanup on WinPE, image index $($IMAGE.ImageIndex)"
        DISM /image:$WINPE_MOUNT /cleanup-image /StartComponentCleanup /ResetBase /Defer 
        if ($LastExitCode -ne 0) {
            throw "Error: Failed to perform image cleanup on WinPE, image index $($IMAGE.ImageIndex). Exit code: $LastExitCode"
        }

        if ($IMAGE.ImageIndex -eq "2") {
            # Save setup.exe for later use. This will address possible binary mismatch with the version in the main OS \sources folder
            Copy-Item -Path $WINPE_MOUNT"\sources\setup.exe" -Destination $WORKING_PATH"\setup.exe" -Force -ErrorAction stop 
        
            # Save setuphost.exe for later use. This will address possible binary mismatch with the version in the main OS \sources folder
            # This is only required starting with Windows 11 version 24H2
            $TEMP = Get-WindowsImage -ImagePath $MEDIA_NEW_PATH"\sources\boot.wim" -Index $IMAGE.ImageIndex
            if ([System.Version]$TEMP.Version -ge [System.Version]"10.0.26100") {
                Copy-Item -Path $WINPE_MOUNT"\sources\setuphost.exe" -Destination $WORKING_PATH"\setuphost.exe" -Force -ErrorAction stop 
            }
            else {
                Write-Output "$(Get-TS): Skipping copy of setuphost.exe; image version $($TEMP.Version)"
            }
        
            # Save serviced boot manager files later copy to the root media.
            Copy-Item -Path $WINPE_MOUNT"\Windows\boot\efi\bootmgfw.efi" -Destination $WORKING_PATH"\bootmgfw.efi" -Force -ErrorAction stop 
            Copy-Item -Path $WINPE_MOUNT"\Windows\boot\efi\bootmgr.efi" -Destination $WORKING_PATH"\bootmgr.efi" -Force -ErrorAction stop 
        }
        
        # Dismount
        Dismount-WindowsImage -Path $WINPE_MOUNT -Save -ErrorAction stop 

        #Export WinPE
        Write-Output "$(Get-TS): Exporting image to $WORKING_PATH\boot2.wim"
        Export-WindowsImage -SourceImagePath $MEDIA_NEW_PATH"\sources\boot.wim" -SourceIndex $IMAGE.ImageIndex -DestinationImagePath $WORKING_PATH"\boot2.wim" -ErrorAction stop 
    }

    Move-Item -Path $WORKING_PATH"\boot2.wim" -Destination $MEDIA_NEW_PATH"\sources\boot.wim" -Force -ErrorAction stop 

    #
    # update remaining files on media
    #

    # Add Setup DU by copy the files from the package into the newMedia
    if ($SETUP_DU_PATH) {
        Write-Output "$(Get-TS): Adding package $SETUP_DU_PATH"
        cmd.exe /c $env:SystemRoot\System32\expand.exe $SETUP_DU_PATH -F:* $MEDIA_NEW_PATH"\sources" 
        if ($LastExitCode -ne 0) {
            throw "Error: Failed to expand $SETUP_DU_PATH. Exit code: $LastExitCode"
        }
    }
    else {
        Write-Warning "$(Get-TS): Skipping Setup Dynamic Update expansion step (no .cab found in packages\Other\SetupDynamic)"
    }

    # Copy setup.exe from boot.wim, saved earlier.
    Write-Output "$(Get-TS): Copying $WORKING_PATH\setup.exe to $MEDIA_NEW_PATH\sources\setup.exe"
    Copy-Item -Path $WORKING_PATH"\setup.exe" -Destination $MEDIA_NEW_PATH"\sources\setup.exe" -Force -ErrorAction stop 

    # Copy setuphost.exe from boot.wim, saved earlier.
    if (Test-Path -Path $WORKING_PATH"\setuphost.exe") {
        Write-Output "$(Get-TS): Copying $WORKING_PATH\setuphost.exe to $MEDIA_NEW_PATH\sources\setuphost.exe"
        Copy-Item -Path $WORKING_PATH"\setuphost.exe" -Destination $MEDIA_NEW_PATH"\sources\setuphost.exe" -Force -ErrorAction stop 
    }

    # Copy bootmgr files from boot.wim, saved earlier.
    $MEDIA_NEW_FILES = Get-ChildItem $MEDIA_NEW_PATH -Force -Recurse -Filter b*.efi

    Foreach ($File in $MEDIA_NEW_FILES) {
        if (($File.Name -ieq "bootmgfw.efi") -or ($File.Name -ieq "bootx64.efi") -or ($File.Name -ieq "bootia32.efi") -or ($File.Name -ieq "bootaa64.efi")) {
            Write-Output "$(Get-TS): Copying $WORKING_PATH\bootmgfw.efi to $($File.FullName)"
            Copy-Item -Path $WORKING_PATH"\bootmgfw.efi" -Destination $File.FullName -Force -ErrorAction stop 
        }
        elseif ($File.Name -ieq "bootmgr.efi") {
            Write-Output "$(Get-TS): Copying $WORKING_PATH\bootmgr.efi to $($File.FullName)"
            Copy-Item -Path $WORKING_PATH"\bootmgr.efi" -Destination $File.FullName -Force -ErrorAction stop 
        }
    }

    #
    # Perform final cleanup
    #

    # Remove our working folder
    Remove-Item -Path $WORKING_PATH -Recurse -Force -ErrorAction stop 

}
catch {
    $_

    $_.Exception
    
    Write-Warning "Something went wrong, attempting to unmount Windows images"

    Get-WindowsImage -Mounted | ForEach-Object {
        Write-Output "$(Get-TS): Dismounting image $($_.Path)"
        Dismount-WindowsImage -Path $_.Path -Discard -ErrorAction SilentlyContinue
    }

    Write-Host "List any mounted images with 'Get-WindowsImage -Mounted' and clean up with 'dism /cleanup-wim'"
    Get-WindowsImage -Mounted
}
finally {
    # Dismount ISO images
    # Write-Output "$(Get-TS): Dismounting ISO images"
    # Dismount-DiskImage -ImagePath $FOD_ISO_PATH -ErrorAction stop 
}

Write-Output "$(Get-TS): Media refresh completed!"