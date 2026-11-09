$env:GRADLE_USER_HOME = "C:\Users\Lenovo\.gradle"
$env:ANDROID_HOME = "D:\Sukkur Salah\Android\sdk"
$env:ANDROID_SDK_ROOT = "D:\Sukkur Salah\Android\sdk"
$env:JAVA_HOME = "D:\Sukkur Salah\jdk17\jdk-17.0.11+9"
$env:PATH = "$env:JAVA_HOME\bin;" + $env:PATH
$version = "v1.4.8"
$buildNumber = "58"
$fullVersion = "$version+$buildNumber"
$destFolder = "D:\Sukkur Salah"
$flutter = "D:\Sukkur Salah\flutter\bin\flutter.bat"

Stop-Process -Name java -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

if (Test-Path "D:\build-sukkur\app\outputs\flutter-apk\app-release.apk") {
    Remove-Item "D:\build-sukkur\app\outputs\flutter-apk\app-release.apk" -Force -ErrorAction SilentlyContinue
}

Write-Host "=== Starting Signed Release APK Build ($fullVersion) ===" -ForegroundColor Cyan
& $flutter build apk --release

if (Test-Path "D:\build-sukkur\app\outputs\flutter-apk\app-release.apk") {
    Write-Host "=== Build Successful! Copying Release APK... ===" -ForegroundColor Green
    Copy-Item "D:\build-sukkur\app\outputs\flutter-apk\app-release.apk" "D:\Sukkur Salah\SukkurSalah-$fullVersion-release.apk" -Force
    Copy-Item "D:\build-sukkur\app\outputs\flutter-apk\app-release.apk" "D:\Sukkur Salah\SukkurSalah-$version-release.apk" -Force
    Copy-Item "D:\build-sukkur\app\outputs\flutter-apk\app-release.apk" "$destFolder\SukkurSalah-release.apk" -Force
    Copy-Item "D:\build-sukkur\app\outputs\flutter-apk\app-release.apk" "D:\Sukkur Salah\Sukkur-Namaz_timings_jantri-main (1)\SukkurSalah-$fullVersion-release.apk" -Force
    Copy-Item "D:\build-sukkur\app\outputs\flutter-apk\app-release.apk" "D:\Sukkur Salah\Sukkur-Namaz_timings_jantri-main (1)\SukkurSalah-$version-release.apk" -Force
    Copy-Item "D:\build-sukkur\app\outputs\flutter-apk\app-release.apk" "D:\Sukkur Salah\Sukkur-Namaz_timings_jantri-main (1)\SukkurSalah-release.apk" -Force
    Write-Host "Done! Release APK saved at:" -ForegroundColor Yellow
    Write-Host "1) D:\Sukkur Salah\Sukkur-Namaz_timings_jantri-main (1)\SukkurSalah-$fullVersion-release.apk" -ForegroundColor Yellow
    Write-Host "2) D:\Sukkur Salah\Sukkur-Namaz_timings_jantri-main (1)\SukkurSalah-$version-release.apk" -ForegroundColor Yellow
} else {
    Write-Error "Release APK build failed to produce app-release.apk"
}

