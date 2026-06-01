$p = Get-Content "$PSScriptRoot\params_$($args[0]).json" | ConvertFrom-Json
$w = @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("dwmapi.dll")]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
}
"@
Add-Type -TypeDefinition $w -ErrorAction SilentlyContinue
$proc = Get-Process -Name $p.App -ErrorAction SilentlyContinue
if ($proc) {
    $h = $proc.MainWindowHandle
    if ($h -ne [IntPtr]::Zero) {
        $a = 3
        $v = 1
        [Win32]::DwmSetWindowAttribute($h, $a, [ref]$v, 4)
        [Win32]::ShowWindow($h, 6)
        $v = 0
        [Win32]::DwmSetWindowAttribute($h, $a, [ref]$v, 4)
        $res = @{ status = "Success"; message = "Bitti" }
    } else {
        $res = @{ status = "Error"; message = "Window handle not found" }
    }
} else {
    $res = @{ status = "Error"; message = "Process not found" }
}
$res | ConvertTo-Json | Out-File "$PSScriptRoot\..\response_$($p.connectionId).json" -Encoding utf8