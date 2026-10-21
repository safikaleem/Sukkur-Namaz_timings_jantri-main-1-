$env:GRADLE_USER_HOME = "C:\Users\Lenovo\.gradle"
$env:ANDROID_HOME = "D:\Sukkur Salah\Android\sdk"
$env:ANDROID_SDK_ROOT = "D:\Sukkur Salah\Android\sdk"
$env:JAVA_HOME = "D:\Sukkur Salah\jdk17\jdk-17.0.11+9"
$env:PATH = "$env:JAVA_HOME\bin;" + $env:PATH
$version = "v1.4.4"
$dest = "D:\Sukkur Salah"
$flutter = "D:\Sukkur Salah\flutter\bin\flutter.bat"
$project = "D:\Sukkur Salah\Sukkur-Namaz_timings_jantri-main (1)"

Set-Location $project

# Clean old outputs so we know we have fresh builds
Remove-Item "D:\build-sukkur\app\outputs\flutter-apk\app-release.apk" -ErrorAction SilentlyContinue
Remove-Item "D:\build-sukkur\app\outputs\bundle\release\app-release.aab" -ErrorAction SilentlyContinue

Write-Host "=== Building APK (Release $version) ===" -ForegroundColor Cyan
& $flutter build apk --release

if (Test-Path "D:\build-sukkur\app\outputs\flutter-apk\app-release.apk") {
    Write-Host "=== Copying APK to $dest ===" -ForegroundColor Cyan
    Copy-Item "D:\build-sukkur\app\outputs\flutter-apk\app-release.apk" "$dest\SukkurSalah-$version-release.apk" -Force
    Copy-Item "D:\build-sukkur\app\outputs\flutter-apk\app-release.apk" "D:\SukkurSalah-$version-release.apk" -Force
    Write-Host "APK build successful!" -ForegroundColor Green
} else {
    Write-Error "APK build failed! app-release.apk not found."
    exit 1
}

Write-Host "=== Building AAB (Release $version) ===" -ForegroundColor Cyan
& $flutter build appbundle --release

if (Test-Path "D:\build-sukkur\app\outputs\bundle\release\app-release.aab") {
    Write-Host "=== Copying AAB to $dest ===" -ForegroundColor Cyan
    Copy-Item "D:\build-sukkur\app\outputs\bundle\release\app-release.aab" "$dest\SukkurSalah-$version-release.aab" -Force
    Copy-Item "D:\build-sukkur\app\outputs\bundle\release\app-release.aab" "D:\SukkurSalah-$version-release.aab" -Force
    Write-Host "AAB build successful!" -ForegroundColor Green
} else {
    Write-Error "AAB build failed! app-release.aab not found."
    exit 1
}

Write-Host ""
Write-Host "=== DONE! Files saved ===" -ForegroundColor Green
Write-Host "APK: $dest\SukkurSalah-$version-release.apk" -ForegroundColor Yellow
Write-Host "AAB: $dest\SukkurSalah-$version-release.aab" -ForegroundColor Yellow

