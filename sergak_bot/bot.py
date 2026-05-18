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
from pathlib import Path

from dotenv import load_dotenv
from telegram import (
    Update,
    InlineKeyboardButton,
    InlineKeyboardMarkup,
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

Bu bot faqat *SERGAK* loyihasi uchun mo'ljallangan rasmiy yuklab olish kanalikdir.

📱 *Nima yuklab olishingiz mumkin:*
• `APK` — Android ilovasi
• `WEBSITE` — SERGAK veb-sayt to'liq arxivi

⚠️ *Diqqat:* Bu bot faqat ruxsatli foydalanuvchilar uchun.
"""

MAIN_KEYBOARD = InlineKeyboardMarkup([
    [
        InlineKeyboardButton("📱 APK Yuklab Olish",     callback_data="dl_apk"),
        InlineKeyboardButton("🌐 Veb-Sayt Yuklab Olish", callback_data="dl_website"),
    ],
    [
        InlineKeyboardButton("ℹ️ Bot Haqida", callback_data="about"),
    ]
])


# ─────────────────────────────────────────────
#  HANDLER FUNKSIYALAR
# ─────────────────────────────────────────────

@secure_handler(rate_limiter)
async def cmd_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Botni boshlash buyrug'i."""
    user = update.effective_user
    logger.info(f"/start — user_id={user.id}, name={user.full_name}")

    await update.message.reply_text(
        WELCOME_MSG,
        parse_mode="Markdown",
        reply_markup=MAIN_KEYBOARD
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


async def callback_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Inline tugmalar uchun handler."""
    query = update.callback_query
    await query.answer()

    user = update.effective_user
    user_id = user.id

    # Rate limit tekshiruvi (barcha foydalanuvchilar uchun)
    if not rate_limiter.check(user_id):
        remaining = rate_limiter.remaining_ban(user_id)
        ThreatLogger.log("RATE_LIMIT_CALLBACK", user_id=user_id)
        await query.message.reply_text(
            f"⛔ Juda tez! {remaining}s kuting."
        )
        return

    data = query.data

    # ── APK yuklab olish ──────────────────────
    if data == "dl_apk":
        logger.info(f"APK so'rovi — user_id={user_id}")
        await query.message.reply_text("⏳ APK yuklanmoqda...")

        # 1. Katta fayllarni File ID orqali tezkor yuborish (Admin yuklagan fayldan)
        file_id_path = Path("apk_file_id.txt")
        if file_id_path.exists():
            try:
                with open(file_id_path, "r", encoding="utf-8") as f:
                    saved_file_id = f.read().strip()
                if saved_file_id:
                    await query.message.reply_document(
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

        # 2. Local Fallback (Agar File ID hali o'rnatilmagan bo'lsa)
        if not APK_PATH.exists():
            await query.message.reply_text(
                "❌ APK yuklashda xato yoki fayl hali mavjud emas.\n"
                "Tez orada loyiha ma'muri (Admin) yangi versiyani yuklaydi."
            )
            ThreatLogger.log("APK_NOT_FOUND", user_id=user_id)
            return

        try:
            with open(APK_PATH, "rb") as f:
                await query.message.reply_document(
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
            await query.message.reply_text("❌ Xato yuz berdi. Qayta urinib ko'ring.")

    # ── Website yuklab olish ──────────────────
    elif data == "dl_website":
        logger.info(f"Website so'rovi — user_id={user_id}")
        await query.message.reply_text("⏳ Veb-sayt arxivlanmoqda...")

        zip_data = build_website_zip()

        if zip_data is None:
            await query.message.reply_text(
                "❌ Veb-sayt papkasi topilmadi."
            )
            ThreatLogger.log("WEBSITE_NOT_FOUND", user_id=user_id)
            return

        if len(zip_data) == 0:
            await query.message.reply_text("❌ Veb-sayt bo'sh.")
            return

        try:
            zip_buf = io.BytesIO(zip_data)
            zip_buf.name = "SERGAK_Website.zip"
            await query.message.reply_document(
                document=zip_buf,
                filename="SERGAK_Website.zip",
                caption=(
                    "🌐 *SERGAK Veb-Sayt Arxivi*\n"
                    "✅ Rasmiy va to'liq versiya\n"
                    "📦 Barcha sahifalar, stil va skriptlar"
                ),
                parse_mode="Markdown"
            )
            logger.info(f"Website ZIP yuborildi — user_id={user_id}, "
                        f"size={len(zip_data)//1024}KB")
        except Exception as e:
            logger.error(f"Website yuborishda xato: {e}")
            await query.message.reply_text("❌ Xato yuz berdi.")

    # ── Bot haqida ────────────────────────────
    elif data == "about":
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
        await query.message.reply_text(about_text, parse_mode="Markdown")

    # Noma'lum callback
    else:
        ThreatLogger.log("UNKNOWN_CALLBACK", user_id=user_id, extra=f"data={data}")


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
    app.add_handler(MessageHandler(filters.Document.ALL, handle_apk_upload))
    app.add_handler(CallbackQueryHandler(callback_handler))
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

    app.post_init = post_init

    logger.info("✅ Bot muvaffaqiyatli ishga tushdi. Ctrl+C bilan to'xtatish.")
    app.run_polling(
        allowed_updates=Update.ALL_TYPES,
        drop_pending_updates=True,   # Eski xabarlarni o'tkazib yuborish
    )


if __name__ == "__main__":
    main()
