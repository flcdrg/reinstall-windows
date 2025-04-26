# https://learn.microsoft.com/windows-hardware/design/component-guidelines/touchpad-tuning-guidelines?WT.mc_id=DOP-MVP-5001655#dynamically-querying-and-modifying-settings

#require -Version 5.1

$source = @'
using System;
using System.Collections.Specialized;
using System.Runtime.InteropServices;
using System.Runtime.Versioning;

public static class SystemParametersInfoHelper
{
    [DllImport("USER32.dll", ExactSpelling = true, EntryPoint = "SystemParametersInfoW", SetLastError = true), DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
    [SupportedOSPlatform("windows5.0")]
    internal static extern unsafe bool SystemParametersInfo(uint uiAction, uint uiParam, [Optional] void* pvParam, uint fWinIni);

    public static void DisableSingleTap()
    {
        const uint SPI_GETTOUCHPADPARAMETERS = 0x00AE;

        //  Sets details about the Precision Touchpad, including user settings and system information related to the touchpad.
        const uint SPI_SETTOUCHPADPARAMETERS = 0x00AF;

        unsafe
        {
            // Use a fixed buffer to handle the managed type issue  
            TOUCHPAD_PARAMETERS param;
            param.VersionNumber = 1;

            var size = (uint)Marshal.SizeOf<TOUCHPAD_PARAMETERS>();
            var result = SystemParametersInfo(SPI_GETTOUCHPADPARAMETERS, size, &param, 0);


            if (param.TapEnabled)
            {
                param.TapEnabled = false;

                result = SystemParametersInfo(SPI_SETTOUCHPADPARAMETERS, size, &param, 3);
            }
        }
    }
}

/// <summary>
/// From <seealso href="https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-touchpad_parameters?WT.mc_id=DOP-MVP-5001655"/>
/// </summary>
[StructLayout(LayoutKind.Sequential)]
public struct TOUCHPAD_PARAMETERS
{
    /// <summary>
    /// The version of the struct.
    /// Caller must set to TOUCHPAD_PARAMETERS_LATEST_VERSION to use the latest version, 
    /// or to TOUCHPAD_PARAMETERS_VERSION_[#] to use a specific version. 
    /// The version must be specified when both reading and writing settings.
    /// </summary>
    public uint VersionNumber;

    /// <summary>
    /// The maximum number of simultaneous contacts (for the touchpad that supports the most) amongst all detected touchpads.
    /// </summary>
    public uint MaxSupportedContacts;

    /// <summary>
    /// The supported features reported by detected legacy touchpads. 
    /// This will be LEGACY_TOUCHPAD_FEATURE_NONE if no legacy touchpads are detected, 
    /// or if the legacy touchpads do not support configuration through SPI_SETTOUCHPADPARAMETERS.
    /// </summary>
    public LEGACY_TOUCHPAD_FEATURES LegacyTouchpadFeatures;

    private BitVector32 First;
    private BitVector32 Second;

    /// <summary>
    /// The touchpad sensitivity level. The more sensitive the touchpad, the less suppression of mouse input generation occurs after keyboard activity.
    /// </summary>
    public TOUCHPAD_SENSITIVITY_LEVEL SensitivityLevel;

    /// <summary>
    /// The rate at which the mouse motion produced by the touchpad moves the cursor. Valid values are 1-20, inclusive.
    /// </summary>
    public uint CursorSpeed;

    /// <summary>
    /// The relative intensity of the touchpad's haptic feedback (if supported). Valid values are 0-100, inclusive.
    /// </summary>
    public uint FeedbackIntensity;

    /// <summary>
    /// The relative sensitivity of the touchpad's haptic click detection (if supported). Valid values are 0-100, inclusive.
    /// </summary>
    public uint ClickForceSensitivity;

    /// <summary>
    /// The relative width of the touchpad right-click zone. Valid values are 0-100, inclusive. If non-zero, this value overrides the device configuration.
    /// </summary>
    public uint RightClickZoneWidth;

    /// <summary>
    /// The relative height of the touchpad right-click zone. Valid values are 0-100, inclusive. If non-zero, this value overrides the device configuration.
    /// </summary>
    public uint RightClickZoneHeight;

    /// <summary>
    /// A Precision Touchpad is detected.
    /// </summary>
    public bool TouchpadPresent
    {
        get => First[1];
        set => First[1] = value;
    }

    /// <summary>
    /// A legacy touchpad is detected.
    /// </summary>
    public bool LegacyTouchpadPresent
    {
        get => First[2];
        set => First[2] = value;
    }

    /// <summary>
    /// An external mouse is detected.
    /// See Precision touchpad tuning for information on exempting a mouse from being considered as external.
    /// </summary>
    public bool ExternalMousePresent
    {
        get => First[4];
        set => First[4] = value;
    }

    /// <summary>
    /// Touchpad input is enabled.
    /// </summary>
    public bool TouchpadEnabled
    {
        get => First[8];
        set => First[8] = value;
    }

    /// <summary>
    /// Touchpad input is active. It is active if it is enabled, and either there is no external mouse detected 
    /// or touchpad input has been configured to stay active despite the presence of an external mouse. 
    /// This field does not indicate whether any touchpad is actively producing input.
    /// </summary>
    public bool TouchpadActive
    {
        get => First[16];
        set => First[16] = value;
    }

    /// <summary>
    /// A detected touchpad supports haptic feedback.
    /// </summary>
    public bool FeedbackSupported
    {
        get => First[32];
        set => First[32] = value;
    }

    /// <summary>
    /// A detected touchpad supports haptic click force.
    /// </summary>
    public bool ClickForceSupported
    {
        get => First[64];
        set => First[64] = value;
    }

    /// <summary>
    /// Touchpad input can remain active if an external mouse is detected. 
    /// When inactive, any input produced by a touchpad is ignored.
    /// </summary>
    public bool AllowActiveWhenMousePresent
    {
        get => Second[1];
        set => Second[1] = value;
    }

    /// <summary>
    /// Haptic feedback is enabled on touchpads if supported.
    /// </summary>
    public bool FeedbackEnabled
    {
        get => Second[2];
        set => Second[2] = value;
    }

    /// <summary>
    /// Single-finger taps are enabled.
    /// </summary>
    public bool TapEnabled
    {
        get => Second[4];
        set => Second[4] = value;
    }

    /// <summary>
    /// Tap-and-drag is enabled.
    /// </summary>
    public bool TapAndDragEnabled
    {
        get => Second[8];
        set => Second[8] = value;
    }

    /// <summary>
    /// Two-finger tap is enabled.
    /// </summary>
    public bool TwoFingerTapEnabled
    {
        get => Second[16];
        set => Second[16] = value;
    }

    /// <summary>
    /// Pressing the bottom-right corner of the touchpad results in a right-click instead of a left click.
    /// If the user has swapped their left and right mouse buttons, the right-click zone is mirrored horizontally to the bottom-left corner of the touchpad.
    /// </summary>
    public bool RightClickZoneEnabled
    {
        get => Second[32];
        set => Second[32] = value;
    }

    /// <summary>
    /// Mouse motion produced by the touchpad honors the user's mouse acceleration setting.
    /// If false, the mouse motion always has acceleration applied.
    /// </summary>
    public bool MouseAccelSettingHonored
    {
        get => Second[64];
        set => Second[64] = value;
    }

    /// <summary>
    /// Two-finger panning is enabled.
    /// </summary>
    public bool PanEnabled
    {
        get => Second[128];
        set => Second[128] = value;
    }

    /// <summary>
    /// Two-finger zooming is enabled.
    /// </summary>
    public bool ZoomEnabled
    {
        get => Second[256];
        set => Second[256] = value;
    }

    /// <summary>
    /// The direction content scrolls with two-finger panning is reversed.
    /// </summary>
    public bool ScrollDirectionReversed
    {
        get => Second[512];
        set => Second[512] = value;
    }
}

[Flags]
public enum LEGACY_TOUCHPAD_FEATURES : uint
{
    LEGACY_TOUCHPAD_FEATURE_NONE = 0x00000000,
    LEGACY_TOUCHPAD_FEATURE_ENABLE_DISABLE = 0x00000001,
    LEGACY_TOUCHPAD_FEATURE_REVERSE_SCROLL_DIRECTION = 0x00000004
}

public enum TOUCHPAD_SENSITIVITY_LEVEL : uint
{
    TOUCHPAD_SENSITIVITY_LEVEL_MOST_SENSITIVE = 0x00000000,
    TOUCHPAD_SENSITIVITY_LEVEL_HIGH_SENSITIVITY = 0x00000001,
    TOUCHPAD_SENSITIVITY_LEVEL_MEDIUM_SENSITIVITY = 0x00000002,
    TOUCHPAD_SENSITIVITY_LEVEL_LOW_SENSITIVITY = 0x00000003,
    TOUCHPAD_SENSITIVITY_LEVEL_LEAST_SENSITIVE = 0x00000004
}
'@

if ($PSVersionTable.PSVersion.Major -eq 5) {
    ($cp = New-Object System.CodeDom.Compiler.CompilerParameters).CompilerOptions = '/unsafe'

    Add-Type -CompilerParameters $cp -TypeDefinition $source -Language CSharp
}
elseif ($PSVersionTable.PSVersion.Major -eq 7) {
    Add-Type -CompilerOptions '/unsafe' $cp -TypeDefinition $source -Language CSharp
}


[SystemParametersInfoHelper]::DisableSingleTap()