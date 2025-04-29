# Things to run after Boxstarter has completed, with elevated permissions

# Fix file ownership on D:
takeown /F D:\ /R /D N > NUL

# Uninstall Boxstarter temp package
choco export

$xml = [xml] (Get-Content .\packages.config)
$tmpPackageName = $xml.packages.package | Where-Object { $_.id.StartsWith("tmp") } | Select-Object -First 1 -ExpandProperty id
choco uninstall $tmpPackageName --skip-autouninstaller --skip-powershell

Remove-Item .\packages.config

