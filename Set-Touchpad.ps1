# https://learn.microsoft.com/windows-hardware/design/component-guidelines/touchpad-tuning-guidelines?WT.mc_id=DOP-MVP-5001655#dynamically-querying-and-modifying-settings


$f=@'
[DllImport("user32.dll")]public static extern int SystemParametersInfo(
    int uAction, 
    int uParam, 
    int lpvParam, 
    int fuWinIni
);
'@

$mSpeed = Add-Type -memberDefinition $f -name "mSpeed" -namespace Win32Functions -passThru
    
$get = 0x0070
$set = 0x0071
    
$srcSpeed = $mSpeed::SystemParametersInfo($get, 0, 0, 0)