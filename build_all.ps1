$env:GRADLE_USER_HOME = "C:\Users\Lenovo\.gradle"
$env:ANDROID_HOME = "D:\Sukkur Salah\Android\sdk"
$env:ANDROID_SDK_ROOT = "D:\Sukkur Salah\Android\sdk"
$env:JAVA_HOME = "D:\Sukkur Salah\jdk17\jdk-17.0.11+9"
$env:PATH = "$env:JAVA_HOME\bin;" + $env:PATH
$version = "v1.4.7"
$destFolder = "D:\Sukkur Salah"
$flutter = "D:\Sukkur Salah\flutter\bin\flutter.bat"

Write-Host "=== 1/2: Building Release APK ($version) ===" -ForegroundColor Cyan
if (Test-Path "D:\build-sukkur\app\outputs\flutter-apk\app-release.apk") {
    Remove-Item "D:\build-sukkur\app\outputs\flutter-apk\app-release.apk" -Force -ErrorAction SilentlyContinue
}
& $flutter build apk --release

if (Test-Path "D:\build-sukkur\app\outputs\flutter-apk\app-release.apk") {
    Write-Host "=== APK Build Succeeded! Copying... ===" -ForegroundColor Green
    Copy-Item "D:\build-sukkur\app\outputs\flutter-apk\app-release.apk" "$destFolder\SukkurSalah-$version-release.apk" -Force
    Copy-Item "D:\build-sukkur\app\outputs\flutter-apk\app-release.apk" "D:\Sukkur Salah\Sukkur-Namaz_timings_jantri-main (1)\SukkurSalah-$version-release.apk" -Force
    Write-Host "APK saved to: $destFolder\SukkurSalah-$version-release.apk" -ForegroundColor Yellow
} else {
    Write-Error "APK build failed!"
    exit 1
}

Write-Host "=== 2/2: Building Release AAB ($version) ===" -ForegroundColor Cyan
if (Test-Path "D:\build-sukkur\app\outputs\bundle\release\app-release.aab") {
    Remove-Item "D:\build-sukkur\app\outputs\bundle\release\app-release.aab" -Force -ErrorAction SilentlyContinue
}
& $flutter build appbundle --release

if (Test-Path "D:\build-sukkur\app\outputs\bundle\release\app-release.aab") {
    Write-Host "=== AAB Build Succeeded! Copying... ===" -ForegroundColor Green
    Copy-Item "D:\build-sukkur\app\outputs\bundle\release\app-release.aab" "$destFolder\SukkurSalah-$version-release.aab" -Force
    Copy-Item "D:\build-sukkur\app\outputs\bundle\release\app-release.aab" "D:\Sukkur Salah\Sukkur-Namaz_timings_jantri-main (1)\SukkurSalah-$version-release.aab" -Force
    Write-Host "AAB saved to: $destFolder\SukkurSalah-$version-release.aab" -ForegroundColor Yellow
} else {
    Write-Error "AAB build failed!"
    exit 1
}

Write-Host "==========================================" -ForegroundColor Green
Write-Host "🎉 ALL BUILDS COMPLETE!" -ForegroundColor Green
Write-Host "APK: $destFolder\SukkurSalah-$version-release.apk" -ForegroundColor Green
Write-Host "AAB: $destFolder\SukkurSalah-$version-release.aab" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
