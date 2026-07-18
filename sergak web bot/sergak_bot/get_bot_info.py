import os
import hmac
import hashlib
import requests
from dotenv import load_dotenv

# Load env variables
load_dotenv()

BOT_TOKEN = os.getenv("BOT_TOKEN", "")
SECRET_KEY = os.getenv("SECRET_KEY", "default_secret_change_me")

print("=================================================================")
print("🛡️ SERGAK TELEGRAM BOT YARDAMCHI TIZIMI")
print("=================================================================")

if not BOT_TOKEN or BOT_TOKEN == "YOUR_BOT_TOKEN_HERE":
    print("❌ Xato: .env faylida BOT_TOKEN topilmadi!")
    exit(1)

try:
    print("⏳ Telegram API orqali bot ma'lumotlari olinmoqda...")
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/getMe"
    response = requests.get(url, timeout=10)
    data = response.json()
    
    if not data.get("ok"):
        print(f"❌ Xato: Telegram API javobi noto'g'ri: {data.get('description')}")
        exit(1)
        
    bot_info = data.get("result", {})
    username = bot_info.get("username", "")
    first_name = bot_info.get("first_name", "")
    
    print("\n✅ Bot Muvaffaqiyatli Aniqlashdi:")
    print(f"  🤖 Bot nomi: {first_name}")
    print(f"  👤 Bot username: @{username}")
    
    # Calculate HMAC SHA256 signature
    signature = hmac.new(
        SECRET_KEY.encode("utf-8"),
        username.encode("utf-8"),
        hashlib.sha256
    ).hexdigest()
    
    print("\n🔑 Veb-Sayt Verification uchun Ma'lumotlar:")
    print("-----------------------------------------------------------------")
    print(f"🔗 Bot Havolasi (OFFICIAL_BOT_URL): https://t.me/{username}")
    print(f"👤 Rasmiy Bot User (txtOfficialBot): @{username}")
    print(f"💎 Kriptografik Imzo (txtSignature): {signature}")
    print("-----------------------------------------------------------------")
    print("\n💡 Ushbu ma'lumotlarni veb-saytingizdagi index.html va script.js ga joylang!")
    
except Exception as e:
    print(f"❌ Xato yuz berdi: {e}")

print("=================================================================")
