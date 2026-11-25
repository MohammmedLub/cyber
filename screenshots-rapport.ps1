# Screenshots voor het adviesrapport "Van Windows 10 naar Windows 11"
#
# Start:   powershell -ExecutionPolicy Bypass -File .\screenshots-rapport.ps1
# Output:  map "Screenshots-W11" op je bureaublad (PNG-bestanden)
#
# Per stap opent het script het juiste venster. Jij zet het klaar en drukt Enter:
#   - venster-stap: klik binnen 3 seconden op het venster, dan wordt dat venster vastgelegd
#   - scherm-stap:  je hebt 5 seconden om iets te tonen (Start, muis op maximaliseren), dan volledig scherm
# Typ s + Enter om een stap over te slaan, q + Enter om te stoppen.
# Let op: vervaag daarna pc-naam, Product ID, Device ID en e-mailadressen. Nooit een herstelsleutel tonen.

$ErrorActionPreference = 'Continue'
$out = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Screenshots-W11'
New-Item -ItemType Directory -Force -Path $out | Out-Null

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32Shot {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr hwnd, int attr, out RECT rect, int size);
}
"@
[Win32Shot]::SetProcessDPIAware() | Out-Null

function Save-Area([int]$x, [int]$y, [int]$w, [int]$h, [string]$name) {
    if ($w -le 0 -or $h -le 0) { Write-Host "  Kon venster niet meten, sla over." -ForegroundColor Red; return }
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($x, $y, 0, 0, $bmp.Size)
    $file = Join-Path $out "$name.png"
    $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Host "  Opgeslagen: $file" -ForegroundColor Green
}

function Shot-Window([string]$name) {
    Write-Host "  Klik nu op het venster... (3 s)"
    Start-Sleep -Seconds 3
    $hwnd = [Win32Shot]::GetForegroundWindow()
    $r = New-Object Win32Shot+RECT
    # 9 = DWMWA_EXTENDED_FRAME_BOUNDS: venster zonder onzichtbare schaduwrand
    [Win32Shot]::DwmGetWindowAttribute($hwnd, 9, [ref]$r, [System.Runtime.InteropServices.Marshal]::SizeOf($r)) | Out-Null
    Save-Area $r.Left $r.Top ($r.Right - $r.Left) ($r.Bottom - $r.Top) $name
}

function Shot-Screen([string]$name) {
    Write-Host "  Toon het nu op het scherm... (5 s)"
    Start-Sleep -Seconds 5
    $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    Save-Area $b.X $b.Y $b.Width $b.Height $name
}

$pchc = Join-Path $env:ProgramFiles 'PCHealthCheck\PCHealthCheck.exe'

# n = bestandsnaam, m = window/screen, t = wat moet zichtbaar zijn, o = wat het script opent
$steps = @(
    @{ n='03_w10-einde-support';       m='window'; t='ALLEEN op een Windows 10-pc: Windows Update met de melding over einde ondersteuning'; o={ Start-Process 'ms-settings:windowsupdate' } },
    @{ n='02-1_systeeminfo';           m='window'; t='Editie, RAM, 64-bit (Info / About)';                          o={ Start-Process 'ms-settings:about' } },
    @{ n='02-2_winver';                m='window'; t='Versie en build';                                             o={ Start-Process 'winver.exe' } },
    @{ n='02-3_bitlocker-status';      m='window'; t='BitLocker aan op C: (GEEN herstelsleutel tonen)';           o={ Start-Process 'control.exe' -ArgumentList '/name Microsoft.BitLockerDriveEncryption' } },
    @{ n='04-1_pc-health-check';       m='window'; t='PC Health Check: klik eerst op "Nu controleren"';            o={ if (Test-Path $pchc) { Start-Process $pchc } else { Write-Host '  PC Health Check niet gevonden: installeer via aka.ms/GetPCHealthCheckApp' -ForegroundColor Yellow } } },
    @{ n='04-1_tpm';                   m='window'; t='Specificatieversie 2.0 (vraagt beheerdersrechten)';         o={ Start-Process 'mmc.exe' -ArgumentList 'tpm.msc' -Verb RunAs } },
    @{ n='04-1_msinfo32';              m='window'; t='BIOS-modus UEFI en Status Secure Boot: Aan';                  o={ Start-Process 'msinfo32.exe' } },
    @{ n='04-1_powershell';            m='window'; t='Uitvoer van Get-Tpm en Confirm-SecureBootUEFI';               o={ Start-Process 'powershell.exe' -Verb RunAs -ArgumentList '-NoExit','-Command','Get-Tpm; Confirm-SecureBootUEFI' } },
    @{ n='04-2_device-security';       m='window'; t='Apparaatbeveiliging: kernisolatie, beveiligingsprocessor, Secure Boot'; o={ Start-Process 'windowsdefender://devicesecurity' } },
    @{ n='04-2_geheugenintegriteit';   m='window'; t='Geheugenintegriteit: Aan';                                    o={ Start-Process 'windowsdefender://coreisolation' } },
    @{ n='04-2_smart-app-control';     m='window'; t='App- en browserbeheer > Smart App Control';                   o={ Start-Process 'windowsdefender://appbrowser' } },
    @{ n='04-2_windows-hello';         m='window'; t='Aanmeldingsopties (Windows Hello)';                           o={ Start-Process 'ms-settings:signinoptions' } },
    @{ n='04-3_windows-update';        m='window'; t='Windows Update met versie';                                   o={ Start-Process 'ms-settings:windowsupdate' } },
    @{ n='04-3_werk-of-school';        m='window'; t='Toegang tot werk of school (alleen op bedrijfs-pc)';          o={ Start-Process 'ms-settings:workplace' } },
    @{ n='04-4_taakbalk-w11';          m='screen'; t='Druk na Enter op de Windows-toets: Start-menu in het midden'; o={ } },
    @{ n='04-4_taakbalk-w10';          m='screen'; t='ALLEEN op een Windows 10-pc: Start-menu open';                o={ } },
    @{ n='06_snap-layouts';            m='screen'; t='Houd na Enter de muis op de knop Maximaliseren van een venster'; o={ Start-Process 'notepad.exe' } },
    @{ n='06_verkenner-tabs';          m='window'; t='Verkenner met 2-3 tabbladen (Ctrl+T)';                        o={ Start-Process 'explorer.exe' } },
    @{ n='06_bureaubladen';            m='screen'; t='Druk na Enter op Windows+Tab, met 2 bureaubladen';            o={ } },
    @{ n='06_pincode-instellen';       m='window'; t='Aanmeldingsopties > Pincode (Windows Hello) > Instellen';     o={ Start-Process 'ms-settings:signinoptions' } },
    @{ n='05_onedrive-backup';         m='window'; t='Windows-back-up / OneDrive-mappen';                           o={ Start-Process 'ms-settings:backup' } },
    @{ n='05_hyper-v-test';            m='window'; t='Hyper-V-beheer met een test-VM (optioneel)';                  o={ Start-Process 'virtmgmt.msc' } }
)

$i = 0
foreach ($s in $steps) {
    $i++
    Write-Host ""
    Write-Host "[$i/$($steps.Count)] $($s.n)" -ForegroundColor Cyan
    Write-Host "  Toon: $($s.t)"
    $a = Read-Host "  Enter = openen, s = overslaan, q = stoppen"
    if ($a -eq 'q') { break }
    if ($a -eq 's') { continue }
    try { & $s.o } catch { Write-Host "  Openen mislukt: $($_.Exception.Message)" -ForegroundColor Yellow }
    $a = Read-Host "  Zet het klaar en druk Enter om de foto te nemen (s = overslaan)"
    if ($a -eq 's') { continue }
    if ($s.m -eq 'screen') { Shot-Screen $s.n } else { Shot-Window $s.n }
}

Write-Host ""
Write-Host "Klaar. Bestanden staan in: $out" -ForegroundColor Green
Start-Process 'explorer.exe' $out
