package com.example.ai_ximoyachi

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat

class FraudMonitorService : Service() {

    companion object {
        const val CHANNEL_SERVICE = "FRAUD_SERVICE_CHANNEL"
        const val CHANNEL_ALERT   = "FRAUD_ALERT_CHANNEL"
        const val NOTIF_SERVICE_ID = 1
        const val NOTIF_ALERT_ID   = 2
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            startForeground(
                NOTIF_SERVICE_ID, 
                buildServiceNotification(),
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            )
        } else {
            startForeground(NOTIF_SERVICE_ID, buildServiceNotification())
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "SHOW_FRAUD_ALERT") {
            val sender  = intent.getStringExtra("sms_sender") ?: "Noma'lum raqam"
            val body    = intent.getStringExtra("sms_body")   ?: ""
            showFraudPushNotification(sender, body)
            triggerVibration()
        }
        return START_STICKY
    }

    // ── Bildirishnomalar kanallarini yaratish ─────────────────────────────────
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NotificationManager::class.java)

            // Fon xizmati kanali (low importance — jim)
            nm.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_SERVICE,
                    "Sergak xizmati",
                    NotificationManager.IMPORTANCE_LOW
                ).apply { description = "Orqa fonda ishlaydi" }
            )

            // Fraud ogohlantirish kanali (high importance — tovush + banner)
            nm.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ALERT,
                    "Fraud ogohlantirishlari",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "SMS firibgarligi aniqlanganda ogohlantiradi"
                    enableVibration(true)
                    setShowBadge(true)
                }
            )
        }
    }

    // ── Fon xizmati uchun doimiy bildirishnoma (minimal) ─────────────────────
    private fun buildServiceNotification(): Notification {
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_SERVICE)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Sergak faol")
            .setContentText("SMS va qo'ng'iroqlar nazoratda")
            .setContentIntent(pendingIntent)
            .setOngoing(true)          // o'chirib bo'lmaydi
            .setSilent(true)           // tovush yo'q
            .build()
    }

    // ── Fraud aniqlanganda — katta Push Notification ─────────────────────────
    private fun showFraudPushNotification(sender: String, body: String) {
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Kodning o'zini ajratib olish (birinchi 4-8 xonali raqam)
        val codeMatch = Regex("""\b\d{4,8}\b""").find(body)
        val code = codeMatch?.value ?: "???"

        val notification = NotificationCompat.Builder(this, CHANNEL_ALERT)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("🚨 FRAUD XAVFI ANIQLANDI!")
            .setContentText("$sender dan shubhali SMS: kod $code")
            // Kengaytirilgan matn (pastga tortganda ko'rinadi)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText(
                        "📱 Kimdan: $sender\n\n" +
                        "💬 SMS: $body\n\n" +
                        "⛔ BU KODNI HECH KIMGA BERMANG!\n" +
                        "Bank va to'lov tizimlari hech qachon SMS kodni so'ramaydi."
                    )
                    .setBigContentTitle("🚨 FRAUD XAVFI ANIQLANDI!")
            )
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)           // bosgandan so'ng yopiladi
            .setPriority(NotificationCompat.PRIORITY_MAX)  // ekran yuqorisida chiqadi
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC) // qulflangan ekranda ham
            .setColor(0xFF005C.toInt())    // Danger neon qizil rang
            .build()

        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIF_ALERT_ID, notification)
    }

    // ── Vibratsiya ────────────────────────────────────────────────────────────
    private fun triggerVibration() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val enabled = prefs.getBoolean("flutter.vibration_enabled", true)
        if (!enabled) return

        val pattern = longArrayOf(0, 800, 300, 800, 300, 800)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vm.defaultVibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
        } else {
            @Suppress("DEPRECATION")
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(pattern, -1)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(NOTIF_SERVICE_ID)
    }
}
