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

# Fix file ownership on D: (Takes around 12 minutes)
Measure-Command { takeown /F D:\ /R /SKIPSL /D N *> $null }

<#
Configure Bitlocker using PowerShell, similar to how Windows UI does it

If I use the Windows 11 UI to enable Bitlocker, it prompts me to select one or more locations to backup the recovery key (eg. Azure AD account, Microsoft account, file, print).

Once complete, I can see the following if I run `Get-BitLockerVolume -MountPoint c`

```text
VolumeType      Mount CapacityGB VolumeStatus           Encryption KeyProtector              AutoUnlock Protection
                Point                                   Percentage                           Enabled    Status
----------      ----- ---------- ------------           ---------- ------------              ---------- ----------
OperatingSystem C:      1,168.93 FullyEncrypted         100        {Tpm, RecoveryPassword}              On
```

If I enable Bitlocker using a PowerShell cmdlet `Enable-BitLocker -MountPoint c: -EncryptionMethod XtsAes128 -TpmProtector -UsedSpaceOnly`

Then the result is that the KeyProtector is only `Tpm`.

I can see that there is an option to run [`Add-BitLockerKeyProtector`](https://learn.microsoft.com/en-au/powershell/module/bitlocker/add-bitlockerkeyprotector?view=windowsserver2025-ps&WT.mc_id=DOP-MVP-5001655) but if you specify `-RecoveryPasswordProtector` then it asks for a password

#>



%>