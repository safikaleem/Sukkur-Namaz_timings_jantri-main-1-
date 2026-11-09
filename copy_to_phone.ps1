$shell = New-Object -ComObject Shell.Application
$pc = $shell.Namespace(17) # 17 = ssfDRIVES (This PC)
$phone = $pc.Items() | Where-Object { $_.Name -like "*Safi*" }

if ($phone) {
    Write-Host "Found Phone: " $phone.Name
    $phoneFolder = $phone.GetFolder
    $storage = $phoneFolder.Items() | Select-Object -First 1
    if ($storage) {
        Write-Host "Storage: " $storage.Name
        $storageFolder = $storage.GetFolder
        $download = $storageFolder.Items() | Where-Object { $_.Name -eq "Download" }
        if ($download) {
            Write-Host "Found Download folder! Copying APK..."
            $downloadFolder = $download.GetFolder
            $downloadFolder.CopyHere("D:\Sukkur Salah\SukkurSalah-debug.apk", 16) # 16 = respond "Yes to All" to any dialog
            Write-Host "Successfully copied to Phone Download folder!"
        } else {
            Write-Host "Download folder not found in storage."
        }
    }
} else {
    Write-Host "Phone not found in This PC."
}

