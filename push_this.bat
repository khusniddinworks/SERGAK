@echo off
title SERGAK - GitHub Push (main)
echo =================================================================
echo         🛡️ SERGAK LOYIHASINI GITHUB'GA PUSH QILISH
echo =================================================================
echo.

:: Hozirgi fayl turgan papkaga o'tish (bo'shliqlar bilan xavfsiz ishlaydi)
cd /d "%~dp0"

echo ⚙️ Git safe directory xavfsizlik sozlamalari tekshirilmoqda...
git config --global --add safe.directory "%cd:\=/%"

echo 🔄 Remote URL manzili yangilanmoqda...
git remote remove origin 2>nul
git remote add origin https://github.com/khusniddinworks/SERGAK.git

echo 📦 Fayllar yuklashga tayyorlanmoqda...
git add .

echo 💾 O'zgarishlar saqlanmoqda (commit)...
git commit -m "feat: 🛡️ SERGAK secure Telegram Bot and anti-tampering website"

echo 🚀 GitHub 'main' tarmog'iga push qilinmoqda...
git branch -M main
git push -u origin main --force

if %ERRORLEVEL% equ 0 (
    echo.
    echo 🎉 MUVAFFARIYATLI YUKLANDI! Loyihangiz GitHub'da faol.
) else (
    echo.
    echo ❌ Qandaydir xato yuz berdi. Iltimos, GitHub tokeningiz yoki loginingizni tekshiring.
)

echo.
echo =================================================================
pause
