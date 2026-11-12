$env:GRADLE_USER_HOME = "C:\Users\Lenovo\.gradle"
$env:ANDROID_HOME = "D:\Sukkur Salah\Android\sdk"
$env:ANDROID_SDK_ROOT = "D:\Sukkur Salah\Android\sdk"
$env:JAVA_HOME = "D:\Sukkur Salah\jdk17\jdk-17.0.11+9"
$env:PATH = "$env:JAVA_HOME\bin;" + $env:PATH
$version = "v1.5.0"
$buildNumber = "60"
$fullVersion = "$version+$buildNumber"
$destFolder = "D:\Sukkur Salah"
$flutter = "D:\Sukkur Salah\flutter\bin\flutter.bat"
$symbolsDir = "$destFolder\symbols"
if (-not (Test-Path $symbolsDir)) { New-Item -ItemType Directory -Path $symbolsDir -Force | Out-Null }

Stop-Process -Name java -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

if (Test-Path "D:\build-sukkur\app\outputs\bundle\release\app-release.aab") {
    Remove-Item "D:\build-sukkur\app\outputs\bundle\release\app-release.aab" -Force -ErrorAction SilentlyContinue
}
Remove-Item "D:\build-sukkur\app\intermediates\assets" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "=== Starting AAB Build (Release $fullVersion) ===" -ForegroundColor Cyan
& $flutter build appbundle --release --split-debug-info="$symbolsDir"

if (Test-Path "D:\build-sukkur\app\outputs\bundle\release\app-release.aab") {
    Write-Host "=== Build Successful! Copying to D: drive... ===" -ForegroundColor Green
    Copy-Item "D:\build-sukkur\app\outputs\bundle\release\app-release.aab" "D:\SukkurSalah-$version-release.aab" -Force
    Copy-Item "D:\build-sukkur\app\outputs\bundle\release\app-release.aab" "$destFolder\SukkurSalah-$version-release.aab" -Force
    Copy-Item "D:\build-sukkur\app\outputs\bundle\release\app-release.aab" "D:\Sukkur Salah\Sukkur-Namaz_timings_jantri-main (1)\SukkurSalah-$version-release.aab" -Force
    Write-Host "Done! AAB saved at:" -ForegroundColor Yellow
    Write-Host "1) D:\SukkurSalah-$version-release.aab" -ForegroundColor Yellow
    Write-Host "2) $destFolder\SukkurSalah-$version-release.aab" -ForegroundColor Yellow
} else {
    Write-Error "AAB build failed to produce app-release.aab"
}
