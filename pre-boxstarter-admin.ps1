# Things to run from admin before Boxstarter runs

# Bitlocker
# OperatingSystem C:      1,168.93 FullyEncrypted         100        {Tpm, RecoveryPassword}              On
# Enable-BitLocker -MountPoint c: -EncryptionMethod XtsAes128 -TpmProtector -UsedSpaceOnly
# Add-BitLockerKeyProtector -MountPoint c -RecoveryPasswordProtector

# Attempt to unlock D: drive if Bitlocker recovery key is available
$bitLockerVolume = Get-BitLockerVolume -MountPoint "D:" -ErrorAction SilentlyContinue
if ($bitLockerVolume) {
    $recoveryProtector = $bitLockerVolume.KeyProtector |
        Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" } |
        Select-Object -First 1

    if ($recoveryProtector) {
        $protectorId = $recoveryProtector.KeyProtectorId.ToString().Trim("{}")
        $recoveryKeyFileName = "BitLocker Recovery Key $protectorId.txt"

        $usbDriveLetters = Get-Volume |
            Where-Object {
                $_.DriveType -eq 'Removable' -and
                $_.FileSystem -eq 'NTFS' -and
                -not [string]::IsNullOrWhiteSpace($_.DriveLetter)
            } |
            ForEach-Object { $_.DriveLetter + ':' }

        $recoveryKeyFile = $null
        foreach ($usbDriveLetter in $usbDriveLetters) {
            $candidatePath = Join-Path $usbDriveLetter $recoveryKeyFileName
            if (Test-Path -LiteralPath $candidatePath) {
                $recoveryKeyFile = $candidatePath
                break
            }

            $candidateDirectory = $usbDriveLetter + "\"
            $recoveryKeyFile = Get-ChildItem -LiteralPath $candidateDirectory -Filter "BitLocker Recovery Key *.txt" -File -ErrorAction SilentlyContinue |
                Where-Object { $_.BaseName -like "*${protectorId}" } |
                Select-Object -First 1 -ExpandProperty FullName

            if ($recoveryKeyFile) {
                break
            }
        }

        if ($recoveryKeyFile) {
            $recoveryKeyText = Get-Content -LiteralPath $recoveryKeyFile -Raw
            $recoveryKeyMatch = [regex]::Match($recoveryKeyText, '(?m)^\s*(\d{6}(?:-\d{6}){7})\s*$')

            if ($recoveryKeyMatch.Success) {
                Unlock-BitLocker -MountPoint "D:" -RecoveryPassword $recoveryKeyMatch.Groups[1].Value
                Enable-BitLockerAutoUnlock -MountPoint "D:" -ErrorAction SilentlyContinue
            }
            else {
                Write-Warning "BitLocker recovery key file was found, but no recovery key value could be extracted from $recoveryKeyFile"
            }
        }
        else {
            Write-Warning "No BitLocker recovery key file matching $protectorId was found on an attached USB drive"
        }
    }
    else {
        Write-Warning "No RecoveryPassword key protector was found for D:"
    }
}
else {
    Write-Warning "BitLocker volume D: was not found"
}

# Fix file ownership on D: (Takes around 25 minutes)
Measure-Command { takeown /F D:\ /R /SKIPSL /D N *> $null }

# Windows 11 should (re)enable Bitlocker on C: automatically

# Remove _Instances folder from VS Cache (it refers to old installations)
$vsCachePath = "D:\VS\cache"
$instancesFolder = Join-Path $vsCachePath "_Instances"
if (Test-Path $instancesFolder) {
    Remove-Item -Recurse -Force $instancesFolder
}