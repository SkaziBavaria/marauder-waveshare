# Marauder Waveshare 1.47B - Terminal-build med Arduino CLI
# Kör: .\build-waveshare.ps1
# Kräver: Arduino CLI (choco install arduino-cli) eller https://github.com/arduino/arduino-cli/releases

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibsDir = Join-Path $ScriptDir "CustomLibraries"
$Fqbn = "esp32:esp32:esp32s3:PartitionScheme=min_spiffs,FlashSize=16M,PSRAM=enabled"
$PlatformUrl = "https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json"

# Kolla Arduino CLI (sök även i vanliga platser)
$arduinoCliPath = $null
$c = Get-Command arduino-cli -ErrorAction SilentlyContinue
if ($c) { $arduinoCliPath = $c.Source }
else {
    $paths = @("C:\Program Files\Arduino CLI", "C:\Program Files (x86)\Arduino CLI", "$env:LOCALAPPDATA\Programs\Arduino CLI")
    foreach ($dir in $paths) {
        if (Test-Path "$dir\arduino-cli.exe") { $arduinoCliPath = "$dir\arduino-cli.exe"; break }
    }
}
if (-not $arduinoCliPath) {
    Write-Host "Arduino CLI hittades inte. Installera:" -ForegroundColor Yellow
    Write-Host "  winget install ArduinoSA.CLI" -ForegroundColor Cyan
    Write-Host "  ELLER: https://github.com/arduino/arduino-cli/releases" -ForegroundColor Cyan
    Write-Host "  Stäng/öppna terminal efter install." -ForegroundColor Gray
    exit 1
}

Write-Host "=== Marauder Waveshare Build ===" -ForegroundColor Green

# Skapa lib-mapp
if (-not (Test-Path $LibsDir)) { New-Item -ItemType Directory -Path $LibsDir | Out-Null }

$repos = @(
    @{ name = "TFT_eSPI"; repo = "Bodmer/TFT_eSPI"; ref = "V2.5.34" },
    @{ name = "NimBLE-Arduino"; repo = "h2zero/NimBLE-Arduino"; ref = "1.3.8" },
    @{ name = "AsyncTCP"; repo = "ESP32Async/AsyncTCP"; ref = "v3.4.8" },
    @{ name = "ESPAsyncWebServer"; repo = "ESP32Async/ESPAsyncWebServer"; ref = "v3.8.1" },
    @{ name = "MicroNMEA"; repo = "stevemarple/MicroNMEA"; ref = "v2.0.6" },
    @{ name = "JPEGDecoder"; repo = "Bodmer/JPEGDecoder"; ref = "1.8.0" },
    @{ name = "XPT2046_Touchscreen"; repo = "PaulStoffregen/XPT2046_Touchscreen"; ref = "v1.4" },
    @{ name = "ESP32Ping"; repo = "marian-craciunescu/ESP32Ping"; ref = "1.6" },
    @{ name = "LinkedList"; repo = "ivanseidel/LinkedList"; ref = "v1.3.3" }
)

foreach ($r in $repos) {
    $path = Join-Path $LibsDir $r.name
    if (Test-Path $path) {
        Write-Host "  [OK] $($r.name) finns" -ForegroundColor DarkGray
    } else {
        Write-Host "  Klonar $($r.name)..." -ForegroundColor Cyan
        try {
            $null = cmd /c "git clone --depth 1 --branch $($r.ref) https://github.com/$($r.repo).git `"$path`" 2>nul"
            if ($LASTEXITCODE -ne 0) { cmd /c "git clone --depth 1 https://github.com/$($r.repo).git `"$path`" 2>nul" | Out-Null }
        } catch { }
    }
}

# TFT_eSPI: kopiera User_Setup och aktivera Waveshare
$tftDir = Join-Path $LibsDir "TFT_eSPI"
Copy-Item (Join-Path $ScriptDir "User_Setup*.h") -Destination $tftDir -Force
$selectPath = Join-Path $tftDir "User_Setup_Select.h"
(Get-Content $selectPath) | ForEach-Object {
    if ($_ -match 'User_Setup_waveshare_1_47b') { $_ -replace '^//', '' }
    elseif ($_ -match '^\s*#include\s+<User_Setup_' -and $_ -notmatch 'waveshare') { "//$_" }
    else { $_ }
} | Set-Content $selectPath -Encoding UTF8

# Arduino CLI (använd full path om hittad i icke-PATH plats)
$cli = if ($arduinoCliPath) { "& `"$arduinoCliPath`"" } else { "arduino-cli" }

# ESP32 2.0.11
Write-Host "  Installerar ESP32 platform 2.0.11..." -ForegroundColor Cyan
Invoke-Expression "$cli core update-index --additional-urls $PlatformUrl" 2>$null
Invoke-Expression "$cli core install esp32:esp32@2.0.11 --additional-urls $PlatformUrl" 2>$null

# Ytterligare libs (om de saknas)
$libDeps = @("ArduinoJson@6.18.2", "Adafruit NeoPixel@1.12.0", "Adafruit BusIO@1.15.0", "Adafruit MAX1704X@1.0.2", "espsoftwareserial@8.1.0")
foreach ($lib in $libDeps) {
    Invoke-Expression "$cli lib install `"$lib`"" 2>$null
}

Write-Host "  Bygger..." -ForegroundColor Cyan
$compileCmd = "$cli compile " +
    "--fqbn $Fqbn " +
    "--libraries $LibsDir " +
    "--build-property `"compiler.cpp.extra_flags=-DMARAUDER_WAVESHARE_1_47B`" " +
    "--warnings default " +
    (Join-Path $ScriptDir "esp32_marauder")
Invoke-Expression $compileCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n=== KLART! ===" -ForegroundColor Green
    $binPath = Join-Path $ScriptDir "esp32_marauder\build\esp32.esp32.esp32s3\esp32_marauder.ino.bin"
    if (Test-Path $binPath) {
        Write-Host "Binär: $binPath" -ForegroundColor Cyan
        Write-Host "Flashes: arduino-cli upload -p COM4 --fqbn $Fqbn esp32_marauder" -ForegroundColor Yellow
    }
} else {
    Write-Host "`nBygget misslyckades." -ForegroundColor Red
    exit 1
}
