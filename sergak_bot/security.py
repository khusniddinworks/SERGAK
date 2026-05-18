"""
SERGAK BOT - XAVFSIZLIK MODULI
================================
Bu modul barcha xavfsizlik funksiyalarini o'z ichiga oladi:
- Rate Limiting (spam himoyasi)
- Anti-hijack himoya (bot tokenini o'g'irlashdan)
- Admin whitelist (faqat ruxsat berilgan foydalanuvchilar)
- Payload HMAC imzolash
- Suspicious activity logging
"""

import os
import time
import hmac
import hashlib
import logging
import asyncio
from collections import defaultdict, deque
from functools import wraps
from typing import Callable

logger = logging.getLogger(__name__)

# ─────────────────────────────────────────────
#  RATE LIMITER
# ─────────────────────────────────────────────
class RateLimiter:
    """
    Har bir foydalanuvchi uchun so'rovlar sonini cheklaydi.
    Sliding window algoritmi asosida ishlaydi.
    """
    def __init__(self, max_requests: int = 5, window_seconds: int = 60):
        self.max_requests = max_requests
        self.window = window_seconds
        self._buckets: dict[int, deque] = defaultdict(deque)
        self._banned: dict[int, float] = {}       # user_id -> ban_end_time
        self._warn_count: dict[int, int] = defaultdict(int)

    def is_banned(self, user_id: int) -> bool:
        if user_id in self._banned:
            if time.time() < self._banned[user_id]:
                return True
            else:
                del self._banned[user_id]
                self._warn_count[user_id] = 0
        return False

    def remaining_ban(self, user_id: int) -> int:
        if user_id in self._banned:
            secs = int(self._banned[user_id] - time.time())
            return max(0, secs)
        return 0

    def check(self, user_id: int) -> bool:
        """True qaytarsa — ruxsat, False qaytarsa — limit oshgan."""
        if self.is_banned(user_id):
            return False

        now = time.time()
        bucket = self._buckets[user_id]

        # Eski so'rovlarni tozalash
        while bucket and bucket[0] < now - self.window:
            bucket.popleft()

        if len(bucket) >= self.max_requests:
            self._warn_count[user_id] += 1
            # 3 marta limit oshsa — 10 daqiqa ban
            ban_time = 600 if self._warn_count[user_id] >= 3 else 60
            self._banned[user_id] = now + ban_time
            logger.warning(
                f"[SECURITY] Rate limit ban: user_id={user_id}, "
                f"warn_count={self._warn_count[user_id]}, ban={ban_time}s"
            )
            return False

        bucket.append(now)
        return True


# ─────────────────────────────────────────────
#  HMAC PAYLOAD IMZOSI
# ─────────────────────────────────────────────
def sign_payload(data: str, secret: str) -> str:
    """Ma'lumotni HMAC-SHA256 bilan imzolash."""
    return hmac.new(
        secret.encode("utf-8"),
        data.encode("utf-8"),
        hashlib.sha256
    ).hexdigest()


def verify_payload(data: str, signature: str, secret: str) -> bool:
    """HMAC imzoni tekshirish (timing-safe)."""
    expected = sign_payload(data, secret)
    return hmac.compare_digest(expected, signature)


# ─────────────────────────────────────────────
#  ADMIN CHECKER
# ─────────────────────────────────────────────
class AdminGuard:
    """
    Faqat whitelist'dagi admin(lar) bot funksiyalarini ishlatishi mumkin.
    Bu bot tokenini o'g'irlashdan himoya qilmaydi (token server tomonida
    saqlanadi), lekin bot javob bermasligini ta'minlaydi.
    """
    def __init__(self, admin_ids: list[int]):
        self._admins = set(admin_ids)

    def is_admin(self, user_id: int) -> bool:
        return user_id in self._admins

    def add(self, user_id: int):
        self._admins.add(user_id)

    def remove(self, user_id: int):
        self._admins.discard(user_id)


# ─────────────────────────────────────────────
#  SUSPICIOUS ACTIVITY LOGGER
# ─────────────────────────────────────────────
class ThreatLogger:
    """Shubhali faoliyatni alohida faylga yozadi."""

    LOG_FILE = "threat_log.txt"

    @staticmethod
    def log(event: str, user_id: int = 0, extra: str = ""):
        msg = (
            f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] "
            f"EVENT={event} | USER={user_id} | {extra}\n"
        )
        logger.warning(msg.strip())
        try:
            with open(ThreatLogger.LOG_FILE, "a", encoding="utf-8") as f:
                f.write(msg)
        except Exception:
            pass  # Log yozish muvaffaqiyatsiz bo'lsa davom etamiz


# ─────────────────────────────────────────────
#  BOT TOKEN ANTI-HIJACK TEKSHIRUVI
# ─────────────────────────────────────────────
async def verify_bot_integrity(application, expected_username: str) -> bool:
    """
    Bot hali ham bizning bot ekanligini tekshiradi.
    Agar token boshqa bot uchun ishlatilsa, dastur to'xtatiladi.
    """
    try:
        bot_info = await application.bot.get_me()
        actual_username = bot_info.username.lower()
        expected_clean = expected_username.lower().lstrip("@")

        if actual_username != expected_clean:
            ThreatLogger.log(
                "BOT_HIJACK_DETECTED",
                extra=(
                    f"Expected @{expected_clean}, "
                    f"got @{actual_username}. SHUTTING DOWN!"
                )
            )
            logger.critical(
                "⛔ BOT HIJACK ANIQLANDI! Bot to'xtatilmoqda..."
            )
            return False

        logger.info(f"✅ Bot yaxlitligi tasdiqlandi: @{actual_username}")
        return True

    except Exception as e:
        logger.error(f"Bot yaxlitligini tekshirishda xato: {e}")
        return False


def secure_handler(rate_limiter: RateLimiter):
    """
    Barcha foydalanuvchilar uchun umumiy handlerlarni himoyalash:
    Faqat Rate limit tekshiradi (spam va DDoS dan himoya).
    """
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(update, context, *args, **kwargs):
            if not update.effective_user:
                return

            user = update.effective_user
            user_id = user.id

            # 1. Rate limit tekshiruvi
            if not rate_limiter.check(user_id):
                remaining = rate_limiter.remaining_ban(user_id)
                ThreatLogger.log(
                    "RATE_LIMIT_BLOCKED",
                    user_id=user_id,
                    extra=f"remaining_ban={remaining}s"
                )
                await update.effective_message.reply_text(
                    f"⛔ Siz juda tez so'rov yubordingiz.\n"
                    f"🕐 {remaining} soniyadan keyin qayta urinib ko'ring."
                )
                return

            return await func(update, context, *args, **kwargs)
        return wrapper
    return decorator


def admin_only(rate_limiter: RateLimiter, admin_guard: AdminGuard):
    """
    Faqat admin uchun mo'ljallangan buyruqlar va boshqaruv paneli himoyasi:
    1. Rate limit tekshiradi
    2. Admin ekanligini tekshiradi
    3. Ruxsatsiz harakatlarni threat_log.txt ga yozadi
    """
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(update, context, *args, **kwargs):
            if not update.effective_user:
                return

            user = update.effective_user
            user_id = user.id

            # 1. Rate limit tekshiruvi
            if not rate_limiter.check(user_id):
                remaining = rate_limiter.remaining_ban(user_id)
                ThreatLogger.log(
                    "RATE_LIMIT_BLOCKED",
                    user_id=user_id,
                    extra=f"remaining_ban={remaining}s"
                )
                await update.effective_message.reply_text(
                    f"⛔ Siz juda tez so'rov yubordingiz.\n"
                    f"🕐 {remaining} soniyadan keyin qayta urinib ko'ring."
                )
                return

            # 2. Admin tekshiruvi
            if not admin_guard.is_admin(user_id):
                ThreatLogger.log(
                    "UNAUTHORIZED_ACCESS",
                    user_id=user_id,
                    extra=f"username=@{user.username}"
                )
                await update.effective_message.reply_text(
                    "🔒 Bu buyruq faqat loyiha ma'muri (Admin) uchun ochiq."
                )
                return

            return await func(update, context, *args, **kwargs)
        return wrapper
    return decorator
