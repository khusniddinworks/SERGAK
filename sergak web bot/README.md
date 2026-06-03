# 🛡️ SERGAK - Oflayn AI Kiberxavfsizlik Ilovasi

**SERGAK** O'zbekistondagi birinchi 100% oflayn rejimda ishlovchi sun'iy intellektga asoslangan kiberxavfsizlik ilovasidir. Ushbu loyiha foydalanuvchilarni firibgarliklardan, xavfli SMS va havolalardan himoya qilishga qaratilgan bo'lib, buning barchasi bevosita foydalanuvchi qurilmasida (Internetga ulanmagan holda) amalga oshiriladi.

## 🌟 Imkoniyatlar

- **Oflayn Kiber-maslahatchi:** Qurilmangiz ichida ishlovchi, xakerlar yetib bora olmaydigan AI.
- **Xavfli SMS va Havolalar tahlili:** Soxta va fishing (phishing) xabarlarni soniyalar ichida aniqlash.
- **Premium Litsenziya tizimi:** Kengaytirilgan imkoniyatlarni taqdim etuvchi 3 oylik va 1 yillik tarif rejalari. Litsenziya backend server orqali HMAC-SHA256 yordamida generatsiya qilinadi.
- **Ikki tilli interfeys:** O'zbek va Rus tillarini qo'llab-quvvatlaydigan qulay veb-sayt.

## 🛠 Texnologiyalar

- **Frontend:** HTML5, CSS3, Vanilla JavaScript.
- **Backend:** Python (aiohttp asosida veb server), python-telegram-bot.
- **Kriptografiya:** HMAC-SHA256 shifrlash usuli orqali xavfsiz kalitlar yaratilishi.

## 🚀 Qanday ishga tushiriladi?

1. Loyiha qismidagi barcha kerakli kutubxonalarni o'rnating:
   ```bash
   cd sergak_bot
   pip install -r requirements.txt
   ```
2. `.env` faylini to'g'ri sozlang va `SECRET_KEY` o'zgaruvchisini qo'shing.
3. Botni va API serverini ishga tushiring:
   ```bash
   python bot.py
   ```
4. `index.html` faylini brauzeringizda ochib, tizimdan foydalanishingiz mumkin.

## 📄 Huquqiy Ma'lumotlar
Ilovadan foydalanish va ma'lumotlar maxfiyligi haqida batafsil ma'lumot olish uchun saytimizdagi [Maxfiylik Siyosati](privacy.html) hamda [Foydalanish shartlari](terms.html) sahifalariga tashrif buyuring.

---
© 2026 SERGAK. Barcha huquqlar himoyalangan.
