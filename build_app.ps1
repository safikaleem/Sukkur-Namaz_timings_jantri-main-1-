$env:GRADLE_USER_HOME = "C:\Users\Lenovo\.gradle"
$env:ANDROID_HOME = "D:\Sukkur Salah\Android\sdk"
$env:ANDROID_SDK_ROOT = "D:\Sukkur Salah\Android\sdk"
$env:JAVA_HOME = "D:\Sukkur Salah\jdk17\jdk-17.0.11+9"
$env:PATH = "$env:JAVA_HOME\bin;" + $env:PATH
$version = "v1.2.2"
$dest = "D:\Sukkur Salah"
$flutter = "D:\Sukkur Salah\flutter\bin\flutter.bat"
$project = "D:\Sukkur Salah\Sukkur-Namaz_timings_jantri-main (1)"

Set-Location $project

Write-Host "=== Building APK ===" -ForegroundColor Cyan
& $flutter build apk --release

Write-Host "=== Copying APK to $dest ===" -ForegroundColor Cyan
Copy-Item "D:\build-sukkur\app\outputs\flutter-apk\app-release.apk" "$dest\SukkurSalah-$version-release.apk" -Force

Write-Host "=== Building AAB ===" -ForegroundColor Cyan
& $flutter build appbundle --release

Write-Host "=== Copying AAB to $dest ===" -ForegroundColor Cyan
Copy-Item "D:\build-sukkur\app\outputs\bundle\release\app-release.aab" "$dest\SukkurSalah-$version-release.aab" -Force

Write-Host ""
Write-Host "=== DONE! Files saved ===" -ForegroundColor Green
Write-Host "APK: $dest\SukkurSalah-$version-release.apk" -ForegroundColor Yellow
Write-Host "AAB: $dest\SukkurSalah-$version-release.aab" -ForegroundColor Yellow
