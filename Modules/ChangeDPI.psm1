function Start-ChangeDPI{
    [cmdletbinding()]
    Param()

    #Get the DPI settings and convert it to the actual percentage for easier reading
    #Found this from here: https://powershell.org/forums/topic/how-to-get-screen-resolution-with-dpi-scaling-in-a-remote-desktop-session/
    $DPISetting = (Get-ItemProperty 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name AppliedDPI).AppliedDPI
    switch ($DPISetting) {
        96 {$actualDPI = 100}
        120 {$actualDPI = 125}
        144 {$actualDPI = 150}
        192 {$actualDPI = 200}
    }

    #Get the screen width in pixels
    $resolution = (Get-WmiObject -Class Win32_VideoController).CurrentHorizontalResolution

    #Get the physical screen size
    $size = Get-WmiObject -Namespace root\wmi -Class WmiMonitorBasicDisplayParams | Select-Object @{N="Size"; E={[System.Math]::Round(([System.Math]::Sqrt([System.Math]::Pow($_.MaxHorizontalImageSize, 2)`
    + [System.Math]::Pow($_.MaxVerticalImageSize, 2))/2.54),2)} } | Select-Object -ExpandProperty Size

    #Only run if the screen DPI is not already at 100% and the screen size is less than 15 inches and the resolution width is between 1900 and 2000
    if ($actualDPI -ne 100 -and $size -lt 15 -and ($resolution -ge 1900 -and $resolution -le 2000)) {

        #Get the monitors in the system.  This will set all monitors on the system to 100%
        $monitors = (get-childitem -path "hkcu:\Control Panel\Desktop\PerMonitorSettings").PSPath

        #Set the DpiValue: 4294967293 refers to -2 and 4294967294 refers to -1.  These numbers are needed because you can't set a negative number in the registry.
        #-1 and -2 refer to the steps down from the "Recommended" DPI value set by windows and this can change from screen to screen.
        #If the recommended DPI is 150%, then setting the vlaue to 4294967293 will turn it down to 100%
        foreach ($_ in $monitors) {
            Set-ItemProperty -Path "$_" -Name "DpiValue" -Value 4294967293
        }

        #Restart the Graphics Driver.  This is supposed to mimic the keyboard shortcut win + ctrl + shift + b.
        #If you do not restart the driver, you need to reboot the machine before the scaling takes place.
        #Found from here: https://stackoverflow.com/questions/57570136/how-to-restart-graphics-drivers-with-powershell-or-c-sharp-without-admin-privile
$source = @"
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
using System.Windows.Forms;
namespace KeyboardSend
{
    public class KeyboardSend
    {
        [DllImport("user32.dll")]
        public static extern void keybd_event(byte bVk, byte bScan, int dwFlags, int dwExtraInfo);
        private const int KEYEVENTF_EXTENDEDKEY = 1;
        private const int KEYEVENTF_KEYUP = 2;
        public static void KeyDown(Keys vKey)
        {
            keybd_event((byte)vKey, 0, KEYEVENTF_EXTENDEDKEY, 0);
        }
        public static void KeyUp(Keys vKey)
        {
            keybd_event((byte)vKey, 0, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, 0);
        }
    }
}
"@
        Add-Type -TypeDefinition $source -ReferencedAssemblies "System.Windows.Forms"

        Function Win($Key, $Key2, $Key3)
        {
            [KeyboardSend.KeyboardSend]::KeyDown("LWin")
            [KeyboardSend.KeyboardSend]::KeyDown("$Key")
            [KeyboardSend.KeyboardSend]::KeyDown("$Key2")
            [KeyboardSend.KeyboardSend]::KeyDown("$Key3")
            [KeyboardSend.KeyboardSend]::KeyUp("LWin")
            [KeyboardSend.KeyboardSend]::KeyUp("$Key")
            [KeyboardSend.KeyboardSend]::KeyUp("$Key2")
            [KeyboardSend.KeyboardSend]::KeyUp("$Key3")
        }
        Win 163 161 66

        # 163 = ctrl key
        # 161 = shift key
        # 66 = b key
    }
}