# =========================================================================
# 🛡️ SERGAK — GITHUB O'TKAZISH VA YUKLASH TIZIMI (PowerShell)
# =========================================================================
Clear-Host
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "         🛡️ SERGAK KIBERXAVFSIZLIK LOYIHASINI GITHUB'GA PUSH    " -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

$workspace = "C:\Users\ki770\OneDrive\Desktop\py_files"
$remoteUrl = "https://github.com/khusniddinworks/SERGAK.git"

# Ishchi papkaga o'tish
Set-Location -Path $workspace

# 1. Git o'rnatilganligini tekshirish
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Xato: Tizimingizda Git topilmadi! Iltimos, Git'ni o'rnating va qayta urining." -ForegroundColor Red
    Pause
    Exit
}

# 2. Xavfsiz papka sozlamasini kiritish (safe.directory ownership xatolarini oldini olish uchun)
Write-Host "⚙️ Git safe directory xavfsizlik sozlamalari yangilanmoqda..." -ForegroundColor Yellow
git config --global --add safe.directory $workspace.Replace('\', '/')

# 3. Git repository initialization
if (!(Test-Path -Path (Join-Path $workspace ".git"))) {
    Write-Host "📁 Git repository faollashtirilmoqda (git init)..." -ForegroundColor Yellow
    git init
    git branch -M main
} else {
    Write-Host "✅ Git repository allaqachon faollashtirilgan." -ForegroundColor Green
}

# 4. Remote URL sozlash
$remotes = git remote
if ($remotes -contains "origin") {
    Write-Host "🔄 Remote URL manzili yangilanmoqda..." -ForegroundColor Yellow
    git remote set-url origin $remoteUrl
} else {
    Write-Host "➕ Remote URL manzili qo'shilmoqda..." -ForegroundColor Yellow
    git remote add origin $remoteUrl
}

# 5. Fayllarni stage qilish
Write-Host "📦 Fayllar yuklashga tayyorlanmoqda (git add)..." -ForegroundColor Yellow
git add .

# 6. Commit qilish
$commitMsg = "feat: 🛡️ SERGAK secure Telegram Bot and hardened anti-tampering landing page website"
Write-Host "💾 O'zgarishlar saqlanmoqda (git commit)..." -ForegroundColor Yellow
git commit -m $commitMsg

# 7. Push qilish
Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "🚀 GitHub'ga yuklashga tayyor. Quyidagi amallarni bajaring:" -ForegroundColor Green
Write-Host "   Agar birinchi marta push qilayotgan bo'lsangiz, GitHub sizdan" -ForegroundColor Yellow
Write-Host "   login yoki shaxsiy token (Personal Access Token) so'rashi mumkin." -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

$confirm = Read-Host "GitHub'ga yuklashni boshlaymizmi? (Y/N)"
if ($confirm.ToUpper() -eq "Y") {
    Write-Host "📤 GitHub'ga yuborilmoqda (git push origin main)..." -ForegroundColor Yellow
    git push -u origin main
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "🎉 Muvaffaqiyatli yuklandi! Loyihangiz GitHub'da faol." -ForegroundColor Green
    } else {
        Write-Host "🔄 Main tarmog'iga push qilishda xato yuz berdi. Master tarmog'i bilan urinib ko'ramiz..." -ForegroundColor Yellow
        git push -u origin master 
        if ($LASTEXITCODE -eq 0) {
             Write-Host "🎉 Muvaffaqiyatli master tarmog'iga yuklandi!" -ForegroundColor Green
        } else {
             Write-Host "❌ Push qilish amalga oshmadi. Iltimos, GitHub login sozlamalarini tekshiring." -ForegroundColor Red
        }
    }
} else {
    Write-Host "🚫 Bekor qilindi." -ForegroundColor Red
}

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Pause
