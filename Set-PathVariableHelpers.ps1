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

    # Build the new path, make sure we don't have consecutive semicolons or a leading semicolon
    $newPath = $OldPath + ";" + $NewLocation
    $newPath = ($newPath -replace ";+", ";").TrimStart(";")

    return $newPath
}
