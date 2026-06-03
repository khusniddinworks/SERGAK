$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$source = Join-Path $scriptPath "assets/images/logo_icon.png.png"
$resDir = Join-Path $scriptPath "android/app/src/main/res"

if (-not (Test-Path $source)) {
    Write-Host "Xato: Source rasm topilmadi: $source" -ForegroundColor Red
    return
}

$mipmaps = Get-ChildItem -Path $resDir -Filter "mipmap-*"

foreach ($mipmap in $mipmaps) {
    $target = Join-Path $mipmap.FullName "ic_launcher.png"
    Copy-Item -Path $source -Destination $target -Force
    Write-Host "Muvaffaqiyatli: $($mipmap.Name) papkasidagi icon yangilandi." -ForegroundColor Green
}
