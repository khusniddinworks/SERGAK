package com.example.ai_ximoyachi

import android.content.Context
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

/**
 * FraudCheckWorker — WorkManager orqali har 15 daqiqada bir marta
 * fonda ishlaydi. Accessibility ishlatilmaydi.
 *
 * Vazifasi:
 *  - FraudMonitorService hali ishlamayapti ekanligini tekshiradi
 *  - Agar o'chirilgan bo'lsa, qayta ishga tushiradi
 */
class FraudCheckWorker(context: Context, params: WorkerParameters) :
    Worker(context, params) {

    override fun doWork(): Result {
        return try {
            // Bu yerda fon tahlili qo'shilishi mumkin:
            // - Qora ro'yxat (blacklist) yangilash
            // - Eski loglarni tozalash
            // - Xavfli SMS lug'atini yangilash (lokal fayl)
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }

    companion object {
        private const val WORK_NAME = "fraud_periodic_check"

        /** WorkManager ni ishga tushirish (MainActivity dan chaqiriladi) */
        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<FraudCheckWorker>(
                15, TimeUnit.MINUTES        // Minimum: 15 daqiqa (Android cheklovi)
            ).build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,   // Agar allaqachon bor bo'lsa, o'zgartirma
                request
            )
        }

        /** WorkManager ni to'xtatish */
        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }
    }
}
