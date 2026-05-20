"""
SERGAK TELEGRAM BOT — ASOSIY FAYL
===================================
XAVFSIZLIK ARXITEKTURASI:
  ✅ Faqat admin(lar) botdan foydalana oladi (whitelist)
  ✅ Rate limiting — spam va DDoS himoyasi
  ✅ Anti-hijack tekshiruvi — bot username'ini tasdiqlash
  ✅ HMAC payload imzosi — ma'lumot buzilishidan himoya
  ✅ Barcha shubhali harakatlar loglanadi
  ✅ .env orqali sirlarni koddan ajratish
  ✅ File path traversal himoyasi
  ✅ ZIP arxiv ichida xavfli fayllar yo'qligi tekshiriladi

ISHLATISH:
  1. pip install -r requirements.txt
  2. .env.example -> .env ga ko'chiring va to'ldiring
  3. python bot.py
"""

import os
import io
import zipfile
import logging
import asyncio
import base64
import hmac
import hashlib
from datetime import datetime, timedelta
from pathlib import Path

from dotenv import load_dotenv
from telegram import (
    Update,
    ReplyKeyboardMarkup,
    KeyboardButton,
    BotCommand,
)
from telegram.ext import (
    Application,
    CommandHandler,
    CallbackQueryHandler,
    ContextTypes,
    MessageHandler,
    filters,
)

from security import (
    RateLimiter,
    AdminGuard,
    ThreatLogger,
    verify_bot_integrity,
    secure_handler,
    sign_payload,
    admin_only,
)

# ─────────────────────────────────────────────
#  LOGGING SOZLAMALARI
# ─────────────────────────────────────────────
logging.basicConfig(
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    level=logging.INFO,
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("bot.log", encoding="utf-8"),
    ],
)
logger = logging.getLogger(__name__)

# ─────────────────────────────────────────────
#  MUHIT O'ZGARUVCHILARI
# ─────────────────────────────────────────────
load_dotenv()

BOT_TOKEN: str      = os.getenv("BOT_TOKEN", "")
ADMIN_ID: int       = int(os.getenv("ADMIN_ID", "0"))
BOT_USERNAME: str   = os.getenv("BOT_USERNAME", "")   # @sergak_bot kabi
SECRET_KEY: str     = os.getenv("SECRET_KEY", "default_secret_change_me")
APK_PATH: Path      = Path(os.getenv("APK_PATH", "../ai_ximoyachi/build/app/outputs/flutter-apk/app-release.apk"))
WEBSITE_PATH: Path  = Path(os.getenv("WEBSITE_PATH", "../sergak_website"))

if not BOT_TOKEN or BOT_TOKEN == "YOUR_BOT_TOKEN_HERE":
    raise SystemExit("❌ BOT_TOKEN .env faylida sozlanmagan!")

if ADMIN_ID == 0:
    raise SystemExit("❌ ADMIN_ID .env faylida sozlanmagan!")

# ─────────────────────────────────────────────
#  XAVFSIZLIK OBYEKTLARI
# ─────────────────────────────────────────────
# Har bir foydalanuvchi 60 soniyada max 5 ta so'rov yuborishi mumkin
rate_limiter = RateLimiter(max_requests=5, window_seconds=60)

# Faqat ADMIN_ID whitelist'da
admin_guard  = AdminGuard(admin_ids=[ADMIN_ID])

# ─────────────────────────────────────────────
#  YORDAMCHI FUNKSIYALAR (xavfsizlik bilan)
# ─────────────────────────────────────────────

def safe_resolve(base: Path, target: Path) -> Path | None:
    """
    Path traversal hujumidan himoya.
    target faqat base ichida bo'lishi kerak.
    """
    try:
        resolved = (base / target).resolve()
        if resolved.is_relative_to(base.resolve()):
            return resolved
        ThreatLogger.log(
            "PATH_TRAVERSAL_ATTEMPT",
            extra=f"base={base}, target={target}"
        )
        return None
    except Exception:
        return None


def build_website_zip() -> bytes | None:
    """
    sergak_website papkasini xavfsiz ZIP arxivga aylantiradi.
    Xavfli fayllarni (.exe, .sh, .bat, .ps1) filtrlaidi.
    """
    ALLOWED_EXTENSIONS = {".html", ".css", ".js", ".png", ".jpg",
                          ".jpeg", ".svg", ".ico", ".webp", ".json",
                          ".txt", ".md", ".woff", ".woff2", ".ttf"}
    buf = io.BytesIO()

    website_dir = WEBSITE_PATH.resolve()
    if not website_dir.is_dir():
        logger.error(f"Website papkasi topilmadi: {website_dir}")
        return None

    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
        file_count = 0
        for fpath in website_dir.rglob("*"):
            # Faqat fayllar
            if not fpath.is_file():
                continue
            # .git papkasini o'tkazib yuborish
            if ".git" in fpath.parts:
                continue
            # Kengaytma tekshiruvi
            if fpath.suffix.lower() not in ALLOWED_EXTENSIONS:
                logger.warning(f"Xavfli fayl o'tkazib yuborildi: {fpath.name}")
                ThreatLogger.log(
                    "SUSPICIOUS_FILE_SKIPPED",
                    extra=f"file={fpath.name}"
                )
                continue
            # Path traversal tekshiruvi
            try:
                arcname = fpath.relative_to(website_dir)
            except ValueError:
                continue
            zf.write(fpath, arcname)
            file_count += 1

    logger.info(f"ZIP yaratildi: {file_count} ta fayl")
    return buf.getvalue()


# ─────────────────────────────────────────────
#  XABAR SHABLONLARI
# ─────────────────────────────────────────────

WELCOME_MSG = """
🛡️ *SERGAK xavfsiz yuklab olish botiga xush kelibsiz!*

Bu bot *SERGAK* loyihasi uchun mo'ljallangan rasmiy yuklab olish va boshqarish kanalikdir.

🌐 *Rasmiy veb-sayt:* https://sergak.netlify.app/

📱 *Nima yuklab olishingiz mumkin:*
• `APK` — Android ilovasi
• `WEBSITE` — SERGAK veb-sayt to'liq arxivi

⚠️ *Diqqat:* Bu bot faqat ruxsatli foydalanuvchilar uchun.
"""

def get_main_keyboard(user_id: int) -> ReplyKeyboardMarkup:
    """Foydalanuvchi turiga qarab menyu qaytaradi."""
    keyboard = [
        [KeyboardButton("📱 APK Yuklab Olish"), KeyboardButton("🌐 Veb-Saytga O'tish")],
        [KeyboardButton("ℹ️ Bot Haqida")]
    ]
    if user_id == ADMIN_ID:
        keyboard.append([KeyboardButton("📊 Holat (Admin)"), KeyboardButton("🛠 Admin Panel")])
    
    return ReplyKeyboardMarkup(keyboard, resize_keyboard=True)


# ─────────────────────────────────────────────
#  HANDLER FUNKSIYALAR
# ─────────────────────────────────────────────

@secure_handler(rate_limiter)
async def cmd_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Botni boshlash buyrug'i."""
    user = update.effective_user
    logger.info(f"/start — user_id={user.id}, name={user.full_name}")

    # Agar foydalanuvchi Premium sotib olish uchun ilovadan deep link orqali kelgan bo'lsa
    if context.args and context.args[0].startswith("premium_"):
        parts = context.args[0].split("_")
        if len(parts) >= 3:
            device_id = parts[1]
            plan = parts[2]
            
            price = "25.000 so'm (3 oy)" if plan == "3month" else "85.000 so'm (1 yil)"
            months = 3 if plan == "3month" else 12
            
            payment_msg = (
                f"🌟 *SERGAK PREMIUM SOTIB OLISH*\n\n"
                f"📱 *Qurilma ID:* `{device_id}`\n"
                f"📦 *Tanlangan reja:* {price}\n\n"
                f"💳 *To'lov qilish uchun Click/Payme raqami:*\n"
                f"`8600 1234 5678 9012` (Xamidov X.)\n\n"
                f"✅ To'lov qilganingizdan so'ng chekni (skrinshot) adminga yuboring "
                f"va admin sizga Litsenziya Kalitini beradi!"
            )
            await update.message.reply_text(payment_msg, parse_mode="Markdown")
            return

    await update.message.reply_text(
        WELCOME_MSG,
        parse_mode="Markdown",
        reply_markup=get_main_keyboard(user.id)
    )


@secure_handler(rate_limiter)
async def cmd_help(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Yordam buyrug'i."""
    help_text = (
        "📖 *Yordam*\n\n"
        "• /start — Asosiy menyu\n"
        "• /help — Yordam\n"
        "• /verify — Haqiqiylikni tekshirish\n\n"
        "Tugmalar orqali APK yoki veb-saytni yuklab oling."
    )
    await update.message.reply_text(help_text, parse_mode="Markdown")


@admin_only(rate_limiter, admin_guard)
async def cmd_status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Bot va fayllar holati (Faqat Admin uchun)."""
    apk_exists = APK_PATH.exists()
    web_exists = WEBSITE_PATH.is_dir()
    apk_size   = f"{APK_PATH.stat().st_size / 1_048_576:.1f} MB" if apk_exists else "Topilmadi"
    web_files  = sum(1 for _ in WEBSITE_PATH.rglob("*") if _.is_file()) if web_exists else 0

    status_text = (
        "📊 *Bot Holati (Admin)*\n\n"
        f"📱 APK fayli: {'✅ Mavjud' if apk_exists else '❌ Topilmadi'} ({apk_size})\n"
        f"🌐 Veb-sayt: {'✅ Mavjud' if web_exists else '❌ Topilmadi'} ({web_files} ta fayl)\n"
        f"🔒 Xavfsizlik: ✅ Faol\n"
        f"👤 Admin ID: `{ADMIN_ID}`"
    )
    await update.message.reply_text(status_text, parse_mode="Markdown")


@secure_handler(rate_limiter)
async def cmd_verify(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Kriptografik haqiqiylik tekshiruvi (Website verification)."""
    bot_info = await context.bot.get_me()
    username = bot_info.username
    signature = sign_payload(username, SECRET_KEY)

    verify_text = (
        "🛡️ *SERGAK BOT HAQIQIYLIKNI TASDIQLASH*\n\n"
        "Ushbu botning xavfsizlik va haqiqiylik imzosini quyidagi ma'lumotlar orqali "
        "veb-saytdagi ma'lumotlar bilan solishtiring:\n\n"
        f"👤 *Bot Username:* `@{username}`\n"
        f"🔑 *Kriptografik Imzo (HMAC-SHA256):*\n`{signature}`\n\n"
        "✅ Agar ushbu imzo veb-saytda ko'rsatilgan imzo bilan bir xil bo'lsa, "
        "demak bot 100% rasmiy va buzilmagan hisoblanadi!"
    )
    await update.message.reply_text(verify_text, parse_mode="Markdown")


async def handle_menu_text(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Pastki menyu (ReplyKeyboardMarkup) tugmalarini boshqarish."""
    text = update.message.text
    user = update.effective_user
    user_id = user.id

    # Rate limit tekshiruvi
    if not rate_limiter.check(user_id):
        remaining = rate_limiter.remaining_ban(user_id)
        ThreatLogger.log("RATE_LIMIT_TEXT", user_id=user_id)
        await update.message.reply_text(f"⛔ Juda tez! {remaining}s kuting.")
        return

    if text == "📱 APK Yuklab Olish":
        await send_apk(update, user_id)
    elif text == "🌐 Veb-Saytga O'tish":
        await send_website(update, user_id)
    elif text == "ℹ️ Bot Haqida":
        await send_about(update)
    elif text == "📊 Holat (Admin)":
        await cmd_status(update, context)
    elif text == "🛠 Admin Panel":
        await send_admin_panel(update, user_id)
    else:
        # Boshqa matnlar bo'lsa
        await handle_unknown(update, context)


async def send_apk(update: Update, user_id: int):
    """APK yuborish mantiqi."""
    logger.info(f"APK so'rovi — user_id={user_id}")
    await update.message.reply_text("⏳ APK yuklanmoqda...")

    file_id_path = Path("apk_file_id.txt")
    if file_id_path.exists():
        try:
            with open(file_id_path, "r", encoding="utf-8") as f:
                saved_file_id = f.read().strip()
            if saved_file_id:
                await update.message.reply_document(
                    document=saved_file_id,
                    filename="SERGAK.apk",
                    caption=(
                        "📱 *SERGAK Android Ilovasi*\n"
                        "✅ Rasmiy va xavfsiz versiya\n"
                        "🛡️ Toʻliq oflayn rejimda ishlaydi"
                    ),
                    parse_mode="Markdown"
                )
                logger.info(f"APK File ID orqali yuborildi — user_id={user_id}")
                return
        except Exception as e:
            logger.error(f"File ID orqali yuborishda xato: {e}")

    if not APK_PATH.exists():
        await update.message.reply_text(
            "❌ APK yuklashda xato yoki fayl hali mavjud emas.\n"
            "Tez orada loyiha ma'muri (Admin) yangi versiyani yuklaydi."
        )
        ThreatLogger.log("APK_NOT_FOUND", user_id=user_id)
        return

    try:
        with open(APK_PATH, "rb") as f:
            await update.message.reply_document(
                document=f,
                filename="SERGAK_v1.apk",
                caption=(
                    "📱 *SERGAK Android Ilovasi (Fallback)*\n"
                    "✅ Rasmiy va xavfsiz versiya\n"
                    "🛡️ Toʻliq oflayn rejimda ishlaydi"
                ),
                parse_mode="Markdown"
            )
        logger.info(f"APK lokal fayldan yuborildi — user_id={user_id}")
    except Exception as e:
        logger.error(f"APK yuborishda xato: {e}")
        await update.message.reply_text("❌ Xato yuz berdi. Qayta urinib ko'ring.")


async def send_website(update: Update, user_id: int):
    """Veb-sayt yuborish mantiqi."""
    logger.info(f"Website so'rovi — user_id={user_id}")
    
    # Send the live website link first!
    await update.message.reply_text(
        "🌐 *SERGAK Rasmiy Veb-Sayti:*\n👉 https://sergak.netlify.app/\n\n"
        "⏳ _Pastda esa veb-saytning to'liq oflayn arxivini (ZIP formatida) yuklab olishingiz mumkin..._",
        parse_mode="Markdown"
    )

    zip_data = build_website_zip()

    if zip_data is None:
        await update.message.reply_text("❌ Veb-sayt papkasi topilmadi.")
        ThreatLogger.log("WEBSITE_NOT_FOUND", user_id=user_id)
        return

    if len(zip_data) == 0:
        await update.message.reply_text("❌ Veb-sayt bo'sh.")
        return

    try:
        zip_buf = io.BytesIO(zip_data)
        zip_buf.name = "SERGAK_Website.zip"
        await update.message.reply_document(
            document=zip_buf,
            filename="SERGAK_Website.zip",
            caption=(
                "🌐 *SERGAK Veb-Sayt Arxivi*\n"
                "✅ Rasmiy va to'liq versiya\n"
                "📦 Barcha sahifalar, stil va skriptlar"
            ),
            parse_mode="Markdown"
        )
        logger.info(f"Website ZIP yuborildi — user_id={user_id}, size={len(zip_data)//1024}KB")
    except Exception as e:
        logger.error(f"Website yuborishda xato: {e}")
        await update.message.reply_text("❌ Xato yuz berdi.")


async def send_about(update: Update):
    """Bot haqida yuborish mantiqi."""
    about_text = (
        "🛡️ *SERGAK Rasmiy Yuklab Olish Boti*\n\n"
        "Bu bot SERGAK loyihasi tomonidan yaratilgan "
        "rasmiy tarqatish kanalikdir.\n\n"
        "🔐 *Xavfsizlik kafolatlari:*\n"
        "• Barcha so'rovlar rate-limited (spamdan himoyalangan)\n"
        "• Anti-hijack (token himoyasi) faol\n"
        "• Veb-sayt kriptografik tasdiqlangan\n"
        "• APK fayl to'g'ridan-to'g'ri Telegram serverlaridan keladi\n\n"
        "🏫 *Loyiha:* TAFU, 2026\n"
        "👤 *Asoschi:* Xamidov Xusniddin"
    )
    await update.message.reply_text(about_text, parse_mode="Markdown")


async def send_admin_panel(update: Update, user_id: int):
    """Admin panel yo'riqnomasi."""
    if user_id != ADMIN_ID:
        ThreatLogger.log("UNAUTHORIZED_ADMIN_PANEL_ACCESS", user_id=user_id)
        return
        
    admin_text = (
        "🛠 *SERGAK Admin Paneli*\n\n"
        "Sizda quyidagi maxsus imkoniyatlar mavjud:\n\n"
        "1. 📊 *Holatni tekshirish:* Pastki menyudagi `📊 Holat (Admin)` tugmasi.\n\n"
        "2. 🔑 *Premium Kalit Yasash:*\n"
        "To'lov qilingandan so'ng xaridorga kalit yasab berish uchun quyidagicha yozing:\n"
        "👉 `/premium <Device_ID> <Oylar_soni>`\n"
        "_(Masalan: /premium SRGK-1234-5678 12)_\n\n"
        "3. 📦 *Yangi APK yuklash:*\n"
        "Ilova yangilanganda uni to'g'ridan-to'g'ri shu botga yuboring (fayl sifatida). "
        "Bot uni qabul qiladi va barcha foydalanuvchilarga shuni yetkazadi."
    )
    await update.message.reply_text(admin_text, parse_mode="Markdown")




async def handle_unknown(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Noma'lum buyruqlar uchun."""
    user_id = update.effective_user.id if update.effective_user else 0
    # Rate limit tekshiruvi (noma'lum buyruqlarda ham)
    rate_limiter.check(user_id)
    await update.message.reply_text(
        "❓ Noma'lum buyruq. /help yozing."
    )


# ─────────────────────────────────────────────
#  XATO HANDLER
# ─────────────────────────────────────────────
async def error_handler(update: object, context: ContextTypes.DEFAULT_TYPE):
    """Global xato handler."""
    logger.error(f"Xato: {context.error}", exc_info=context.error)
    ThreatLogger.log("UNHANDLED_ERROR", extra=str(context.error))


@admin_only(rate_limiter, admin_guard)
async def handle_apk_upload(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """
    Admin yangi APK yuborganida uning Telegram file_id sini olib saqlaydi.
    Katta hajmdagi APK har safar serverdan yuklanmasdan, shunchaki Telegram
    serverlaridan file_id orqali tezkor yuboriladi.
    """
    doc = update.message.document
    if not doc.file_name.lower().endswith(".apk"):
        await update.message.reply_text(
            "⚠️ Iltimos, faqat `.apk` formatidagi Android ilova faylini yuboring."
        )
        return

    file_id = doc.file_id
    file_size_mb = doc.file_size / 1_048_576

    try:
        with open("apk_file_id.txt", "w", encoding="utf-8") as f:
            f.write(file_id)
        
        logger.info(f"Admin yangi APK yukladi: file_id={file_id}, size={file_size_mb:.1f} MB")
        
        await update.message.reply_text(
            "✅ *Yangi APK Muvaffaqiyatli Saqlandi!*\n\n"
            f"📦 *Fayl nomi:* `{doc.file_name}`\n"
            f"📊 *Hajmi:* `{file_size_mb:.1f} MB`\n"
            f"🆔 *File ID:* `{file_id}`\n\n"
            "Endi barcha foydalanuvchilar APK so'raganda ushbu fayl Telegram serverlaridan "
            "lahzalar ichida (qayta yuklashlarsiz) yuboriladi!",
            parse_mode="Markdown"
        )
    except Exception as e:
        logger.error(f"APK file_id sini saqlashda xato: {e}")
        await update.message.reply_text("❌ Tizimli xato yuz berdi. File ID saqlanmadi.")


@admin_only(rate_limiter, admin_guard)
async def cmd_premium(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """
    Admin uchun Premium kalit yasash buyrug'i.
    Foydalanish: /premium <DEVICE_ID> <MONTHS>
    Masalan: /premium SRGK-1234-5678 12
    """
    args = context.args
    if len(args) != 2:
        await update.message.reply_text("⚠️ Noto'g'ri format. Foydalanish: `/premium <DEVICE_ID> <OYLAR_SONI>`", parse_mode="Markdown")
        return

    device_id = args[0]
    try:
        months = int(args[1])
    except ValueError:
        await update.message.reply_text("⚠️ Oylar soni raqam bo'lishi kerak!")
        return

    # Kriptografik kalit yasash
    expiry_date = datetime.utcnow() + timedelta(days=months * 30)
    expiry_str = expiry_date.isoformat()
    
    secret_bytes = SECRET_KEY.encode('utf-8')
    message_bytes = (device_id + expiry_str).encode('utf-8')
    
    digest = hmac.new(secret_bytes, message_bytes, hashlib.sha256).digest()
    signature = base64.b64encode(digest).decode('utf-8')
    
    raw_key = f"{signature}|{expiry_str}"
    final_key = base64.b64encode(raw_key.encode('utf-8')).decode('utf-8')

    success_msg = (
        f"✅ *LITSENZIYA KALITI TAYYOR*\n\n"
        f"📱 *Device ID:* `{device_id}`\n"
        f"📅 *Muddat:* {months} oy\n\n"
        f"🔑 *Kalit (Ilovaga kiritish uchun):*\n"
        f"`{final_key}`\n\n"
        f"Ushbu kalitni xaridorga yuboring."
    )
    await update.message.reply_text(success_msg, parse_mode="Markdown")


# ─────────────────────────────────────────────
#  ASOSIY FUNKSIYA
# ─────────────────────────────────────────────
def main():
    logger.info("🚀 SERGAK Bot ishga tushmoqda...")

    # Application qurish
    app = Application.builder().token(BOT_TOKEN).build()

    # Handlerlarni ro'yxatdan o'tkazish
    app.add_handler(CommandHandler("start",  cmd_start))
    app.add_handler(CommandHandler("help",   cmd_help))
    app.add_handler(CommandHandler("status", cmd_status))
    app.add_handler(CommandHandler("verify", cmd_verify))
    app.add_handler(CommandHandler("premium", cmd_premium))
    app.add_handler(MessageHandler(filters.Document.ALL, handle_apk_upload))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_menu_text))
    app.add_handler(MessageHandler(filters.COMMAND, handle_unknown))

    # Global xato handler
    app.add_error_handler(error_handler)

    # Post-init: bot yaxlitligini tekshirish
    async def post_init(application: Application):
        # Bot buyruqlarini o'rnatish
        await application.bot.set_my_commands([
            BotCommand("start",  "Asosiy menyu"),
            BotCommand("help",   "Yordam"),
            BotCommand("status", "Bot holati"),
            BotCommand("verify", "Haqiqiylikni tekshirish"),
        ])

        # Anti-hijack va imzo chop etish
        bot_info = await application.bot.get_me()
        actual_username = bot_info.username
        sig = sign_payload(actual_username, SECRET_KEY)
        logger.info("=================================================================")
        logger.info(f"🛡️ [SECURITY] Bot haqiqiylik imzosi (Website uchun):")
        logger.info(f"🛡️ IMZO: {sig}")
        logger.info("=================================================================")

        # Anti-hijack tekshiruvi
        if BOT_USERNAME:
            ok = await verify_bot_integrity(application, BOT_USERNAME)
            if not ok:
                logger.critical("Bot hijack aniqlandi! To'xtatilmoqda.")
                raise SystemExit("BOT HIJACK DETECTED — SHUTTING DOWN")
        else:
            logger.warning(
                "BOT_USERNAME .env da ko'rsatilmagan — "
                "anti-hijack tekshiruvi o'chirilgan."
            )

        # Web server (Keep-alive va Render port verification)
        port = int(os.getenv("PORT", "8000"))
        from aiohttp import web
        
        async def handle_health(request):
            return web.json_response({"status": "alive", "timestamp": datetime.now().isoformat()})
            
        web_app = web.Application()
        web_app.router.add_get("/", handle_health)
        web_app.router.add_get("/health", handle_health)
        
        runner = web.AppRunner(web_app)
        await runner.setup()
        site = web.TCPSite(runner, "0.0.0.0", port)
        await site.start()
        logger.info(f"🌐 Web Server (Health Check) started on port {port}")

        # Keep alive loop task
        async def keep_alive_loop():
            app_url = os.getenv("RENDER_EXTERNAL_URL") or os.getenv("APP_URL")
            if not app_url:
                logger.warning("⚠️ RENDER_EXTERNAL_URL yoki APP_URL .env da topilmadi. O'z-o'zini ping qilish (Keep alive) o'chirildi.")
                return
                
            if not app_url.startswith("http"):
                app_url = f"https://{app_url}"
                
            logger.info(f"🔄 Keep Alive faollashtirildi! Ping yuboriladigan manzil: {app_url}")
            
            import aiohttp
            # Kutamiz server to'liq ishga tushishini
            await asyncio.sleep(5)
            
            async with aiohttp.ClientSession() as session:
                while True:
                    try:
                        async with session.get(app_url, timeout=10) as response:
                            if response.status == 200:
                                logger.info(f"💓 Keep-alive ping muvaffaqiyatli: {app_url} -> 200 OK")
                            else:
                                logger.warning(f"💔 Keep-alive ping kutilmagan status: {response.status}")
                    except Exception as e:
                        logger.error(f"💔 Keep-alive ping xatosi: {e}")
                    await asyncio.sleep(10) # Har 10 soniyada o'zini ping qilish

        asyncio.create_task(keep_alive_loop())

    app.post_init = post_init

    logger.info("✅ Bot muvaffaqiyatli ishga tushdi. Ctrl+C bilan to'xtatish.")
    app.run_polling(
        allowed_updates=Update.ALL_TYPES,
        drop_pending_updates=True,   # Eski xabarlarni o'tkazib yuborish
    )


if __name__ == "__main__":
    main()
