package com.example.ai_ximoyachi

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Telephony
import android.telephony.TelephonyManager

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            for (sms in messages) {
                val messageBody = sms.messageBody?.lowercase() ?: ""
                val sender = sms.originatingAddress ?: ""
                
                val codePattern = Regex("\\b\\d{4,8}\\b")
                val hasCode = codePattern.containsMatchIn(messageBody)
                
                val keywords = listOf("kod", "parol", "tasdiqlash", "bank", "click", "payme")
                val hasKeyword = keywords.any { messageBody.contains(it) }

                val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
                val isCallActive = telephonyManager?.callState != TelephonyManager.CALL_STATE_IDLE ?: false

                // AGAR: Qo'ng'iroq bo'layotgan bo'lsa + Kod bo'lsa + Kalit so'z bo'lsa -> Bu Fraud!
                if (isCallActive && hasCode && hasKeyword) {
                    // 1. Hisoblagichni oshirish (Real data uchun)
                    val prefs = context.getSharedPreferences("sergak_stats", Context.MODE_PRIVATE)
                    val current = prefs.getInt("dangerous_count", 0)
                    prefs.edit().putInt("dangerous_count", current + 1).apply()

                    // 2. Servisni ishga tushirish
                    val serviceIntent = Intent(context, FraudMonitorService::class.java).apply {
                        action = "SHOW_FRAUD_ALERT"
                        putExtra("sms_sender", sender)
                        putExtra("sms_body", sms.messageBody)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                }
            }
        }
    }
}
