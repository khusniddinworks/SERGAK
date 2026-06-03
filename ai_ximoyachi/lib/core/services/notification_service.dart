import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../state/app_state.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  final List<String> _templates = [
    "Hech qachon bank kartangiz parolini hech kimga aytmang.",
    "SMS orqali kelgan havolalarga (link) shubhali bo'lsa kirmang.",
    "Bank xodimlari sizdan hech qachon SMS kodni so'rashmaydi.",
    "Ilovangizni faqat rasmiy do'konlardan (Play Store) yuklab oling.",
    "Notanish raqamlardan kelgan 'yutuq yutdingiz' mazmunidagi xabarlarga ishonmang.",
    "Click yoki Payme parolini hech kimga bermang.",
    "Telefoningizga notanish APK fayllarni o'rnatishdan saqlaning.",
    "Ikki bosqichli autentifikatsiyani (2FA) barcha muhim akkauntlarda yoqing.",
    "Ochiq Wi-Fi tarmoqlarida bank amaliyotlarini bajarmang.",
    "Parollaringizni har 3 oyda bir marta yangilab turing.",
    "Bitta parolni barcha saytlar uchun ishlatmang.",
    "Kartangiz bloklandi degan qo'ng'iroqlarga ishonmang, bankka o'zingiz qo'ng'iroq qiling.",
    "Shaxsiy ma'lumotlaringizni ijtimoiy tarmoqlarda ochiq qoldirmang.",
    "Qurilmangizning operatsion tizimini doim yangilab turing.",
    "E-mail orqali kelgan shubhali fayllarni yuklab olmang.",
    "Urgent (shoshilinch) deb yozilgan xabarlar ko'pincha firibgarlik belgisidir.",
    "Ilovaga kirishda biometrik (barmoq izi) himoyasidan foydalaning.",
    "Kartangizdagi limitlarni o'rnatib qo'ying.",
    "Shubhali saytlarda karta ma'lumotlarini kiritmang.",
    "Doimiy ravishda bank ko'chirmalarini tekshirib turing.",
    "Notanish shaxslarga masofaviy boshqarish (AnyDesk) ruxsatini bermang.",
    "Telegram'dagi 'Rasmiy bot' deb atalgan soxta botlardan ehtiyot bo'ling.",
    "Onlayn xaridlar uchun alohida virtual kartadan foydalaning.",
    "Davlatdan kompensatsiya berilyapti degan yolg'on saytlarga kirmang.",
    "Parol sifatida tug'ilgan kuningizni ishlatmang.",
    "SMS-kod — bu sizning raqamli imzoingiz, uni hech kimga bermang.",
    "Qurilmangiz yo'qolsa, darhol bank kartalarini bloklang.",
    "HTTPS bo'lmagan saytlarga shaxsiy ma'lumot kiritmang.",
    "Fake (soxta) adminlardan kelgan xabarlarga javob bermang.",
    "Account verify deb so'ralgan shubhali linklarni ochmang.",
    "Doim antivirus ilovasi o'rnatilganiga ishonch hosil qiling.",
    "Begona odamlarning telefonini ishlatib turing deb bermang.",
    "Brauzerda parollarni saqlab qolish xizmatidan ehtiyot bo'ling.",
    "QR-kodlarni skanerlashdan oldin ularning ishonchliligini tekshiring.",
    "Ijtimoiy muhandislik — firibgarlarning eng kuchli quroli.",
    "Sizga yirik meros qoldi kabi xabarlar 100% yolg'on.",
    "PIN kodni karta ustiga yozib qo'ymang.",
    "Bank kartangizning CVV kodini hech kimga ko'rsatmang.",
    "Telefoningiz ekranini doim bloklab qo'ying.",
    "Ilova ruxsatlarini doim nazorat qiling.",
    "Verify account deb nomlangan soxta emaillardan ehtiyot bo'ling.",
    "Telegram guruhlarda tarqalgan shubhali fayllarni ochmang.",
    "Pul o'tkazishdan oldin qabul qiluvchining ismini tekshiring.",
    "Yordam berish niqobi ostidagi firibgarlardan saqlaning.",
    "Google akkauntingiz xavfsizlik sozlamalarini tekshiring.",
    "Shubhali ilovalarni o'chirib tashlang.",
    "VPN ishlatganda bank ilovalariga kirmaslikka harakat qiling.",
    "Har doim tranzaksiya haqida SMS xabarnomani yoqing.",
    "Notanish raqamlar orqali kelgan Foto fayllari virus bo'lishi mumkin.",
    "Xavfsizlik — bu jarayon, bir martalik ish emas. Doim hushyor bo'ling!",
  ];

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Tashkent'));
    } catch (e) {
      debugPrint("Timezone error: $e. Falling back to UTC.");
      tz.setLocalLocation(tz.UTC);
    }
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Bildirishnoma ruxsatini so'raymiz (Android 13+ uchun o'ta muhim)
    await Permission.notification.request();
  }

  Future<void> scheduleDailyNotifications() async {
    // Agar foydalanuvchi Premium bo'lmasa, eslatmalarni bekor qilamiz va chiqamiz
    if (!AppState().isPremium) {
      await _notificationsPlugin.cancelAll();
      return;
    }

    // 8:00 AM
    await _scheduleNotification(8, 0, 100);
    // 3:00 PM (15:00)
    await _scheduleNotification(15, 0, 200);
  }

  Future<void> _scheduleNotification(int hour, int minute, int baseId) async {
    final prefs = await SharedPreferences.getInstance();
    final random = Random();
    
    // Keyingi 7 kun uchun rejalashtiramiz (takrorlanishni kamaytirish uchun)
    for (int day = 0; day < 7; day++) {
      int index = random.nextInt(_templates.length);
      
      // 48 soat ichida (oxirgi 4 ta xabar) takrorlanmasligini tekshirish
      List<String> lastUsed = prefs.getStringList('last_notif_indices') ?? [];
      while (lastUsed.contains(index.toString())) {
        index = random.nextInt(_templates.length);
      }
      
      // Tarixni yangilash
      lastUsed.add(index.toString());
      if (lastUsed.length > 10) lastUsed.removeAt(0);
      await prefs.setStringList('last_notif_indices', lastUsed);

      final scheduledDate = _nextInstanceOfTime(hour, minute, addDays: day);
      
      // Ruxsat borligini tekshiramiz
      final canScheduleExact = await Permission.scheduleExactAlarm.isGranted;

      await _notificationsPlugin.zonedSchedule(
        baseId + day,
        '🛡 Sergak Xavfsizlik',
        _templates[index],
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_tips_channel',
            'Kundalik maslahatlar',
            channelDescription: 'Xavfsizlik bo\'yicha kundalik eslatmalar',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: canScheduleExact 
            ? AndroidScheduleMode.exactAllowWhileIdle 
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // Haftalik takrorlanadigan kunlik aylanish uchun
      );
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute, {int addDays = 0}) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    if (addDays > 0) {
      scheduledDate = scheduledDate.add(Duration(days: addDays));
    }
    
    return scheduledDate;
  }
}
