@echo off
title SERGAK - Git Submodule Fix
echo =================================================================
echo        🛡️ SERGAK - GIT SUBMODULE VA BO'SH PAPKALARNI TUZATISH
echo =================================================================
echo.

:: Hozirgi papkaga o'tish
cd /d "%~dp0"

echo ⏳ 1. Ichki .git papkalarni o'chirish (Nested Git repositories)...
if exist "sergak_bot\.git" (
    echo    - sergak_bot ichidagi .git o'chirilmoqda...
    rmdir /s /q "sergak_bot\.git"
)
if exist "sergak_website\.git" (
    echo    - sergak_website ichidagi .git o'chirilmoqda...
    rmdir /s /q "sergak_website\.git"
)

echo.
echo ⏳ 2. Git keshi va soxta submodullarni o'chirish...
git rm --cached -r sergak_bot 2>nul
git rm --cached -r sergak_website 2>nul

echo.
echo ⏳ 3. Barcha fayllarni qaytadan qo'shish...
git add .

echo.
echo ⏳ 4. Yangi xavfsiz commit yaratish...
git commit -m "fix: resolve nested submodules and upload all bot and website files"

echo.
echo 🚀 5. GitHub 'main' tarmog'iga push qilish...
git push -u origin main --force

if %ERRORLEVEL% equ 0 (
    echo.
    echo 🎉 MUVAFFARIYATLI TUZATILDI VA YUKLANDI!
    echo Endi GitHub sahifangizda barcha fayllarni ochib ko'ra olasiz!
) else (
    echo.
    echo ❌ Push qilishda xato yuz berdi. Iltimos, GitHub token yoki sozlamalarini tekshiring.
)

echo.
echo =================================================================
pause
