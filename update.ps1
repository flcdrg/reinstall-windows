#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-TS { return "{0:HH:mm:ss}" -f [DateTime]::Now }

Write-Output "$(Get-TS): Starting media refresh"

# Declare Dynamic Update packages. A dedicated folder is used for the latest cumulative update, and as needed
# checkpoint cumulative updates.
$LCU_PATH = "C:\mediaRefresh\packages\CU\"

$LCU_SERVICE_STACK = $LCU_PATH + "windows11.0-kb5043080-x64_953449672073f8fb99badb4cc6d5d7849b9c83e8.msu"
$LCU_CU_PATH = $LCU_PATH + "windows11.0-kb5055523-x64_b1df8c7b11308991a9c45ae3fba6caa0e2996157.msu"

$SETUP_DU_PATH = "C:\mediaRefresh\packages\Other\SetupDynamic\windows11.0-kb5055643-x64_11bedc2e384c9f4f8db1ef551e438e4dce181202.cab"
$SAFE_OS_DU_PATH = "C:\mediaRefresh\packages\Other\SafeOSDynamic\windows11.0-kb5057781-x64_0c527ae1d79c06327de2eff7779aa430181eee9b.cab"
$DOTNET_CU_PATH = "C:\mediaRefresh\packages\Other\windows11.0-kb5054979-x64-ndp481_8e2f730bc747de0f90aaee95d4862e4f88751c07.msu"

# Declare media for FOD and LPs
#$FOD_ISO_PATH = "C:\mediaRefresh\packages\mul_languages_and_optional_features_for_windows_11_version_24h2_x64_dvd_eb44bee0.iso"

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
    'Microsoft-Windows-Subsystem-Linux'
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
$MEDIA_OLD_PATH = "C:\mediaRefresh\oldMedia\Ge\client_professional_en-us"
$MEDIA_NEW_PATH = "C:\mediaRefresh\newMedia"
$WORKING_PATH = "C:\mediaRefresh\temp"
$MAIN_OS_MOUNT = "C:\mediaRefresh\temp\MainOSMount"
$WINRE_MOUNT = "C:\mediaRefresh\temp\WinREMount"
$WINPE_MOUNT = "C:\mediaRefresh\temp\WinPEMount"

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

Get-ChildItem -Path $MEDIA_NEW_PATH -Recurse | Where-Object { -not $_.PSIsContainer -and $_.IsReadOnly } | ForEach-Object { $_.IsReadOnly = $false }

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
    $selectedImages = @($WINOS_IMAGES[5])
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
            Write-Output "$(Get-TS): Adding package $LCU_SERVICE_STACK to WinRE"        
            try {
                Add-WindowsPackage -Path $WINRE_MOUNT -PackagePath $LCU_SERVICE_STACK   
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
            Write-Output "$(Get-TS): Adding package $SAFE_OS_DU_PATH to WinRE"
            Add-WindowsPackage -Path $WINRE_MOUNT -PackagePath $SAFE_OS_DU_PATH -ErrorAction stop 

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
        Write-Output "$(Get-TS): Adding package $LCU_SERVICE_STACK to main OS, index $($IMAGE.ImageIndex)"
        Add-WindowsPackage -Path $MAIN_OS_MOUNT -PackagePath $LCU_SERVICE_STACK

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

        # Add latest cumulative update
        Write-Output "$(Get-TS): Adding package $LCU_CU_PATH to main OS, index $($IMAGE.ImageIndex)"
        Add-WindowsPackage -Path $MAIN_OS_MOUNT -PackagePath $LCU_CU_PATH -ErrorAction stop 

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
        Write-Output "$(Get-TS): Adding package $DOTNET_CU_PATH to main OS, index $($IMAGE.ImageIndex)"
        Add-WindowsPackage -Path $MAIN_OS_MOUNT -PackagePath $DOTNET_CU_PATH -ErrorAction stop 

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
            Write-Output "$(Get-TS): Adding package $LCU_SERVICE_STACK to WinPE, image index $($IMAGE.ImageIndex)"
            Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $LCU_SERVICE_STACK   
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
        Write-Output "$(Get-TS): Adding package $LCU_CU_PATH to WinPE, image index $($IMAGE.ImageIndex)"
        Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $LCU_CU_PATH -ErrorAction stop 

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
    Write-Output "$(Get-TS): Adding package $SETUP_DU_PATH"
    cmd.exe /c $env:SystemRoot\System32\expand.exe $SETUP_DU_PATH -F:* $MEDIA_NEW_PATH"\sources" 
    if ($LastExitCode -ne 0) {
        throw "Error: Failed to expand $SETUP_DU_PATH. Exit code: $LastExitCode"
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