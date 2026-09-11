package com.detatech.Azkar

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.content.ContextCompat

/**
 * One-shot alarm fired at the countdown window start (e.g. 20 min before
 * adhan). Forwards the stored details to [CountdownForegroundService] so the
 * live countdown starts even if the app is dead or the device is in Doze.
 * Armed from Dart via MainActivity `countdown_service/scheduleStart`.
 */
class CountdownAlarmReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION = "com.detatech.Azkar.COUNTDOWN_START"
        const val REQUEST_CODE = 9001

        const val EXTRA_TIMESTAMP = "extra_timestamp"
        const val EXTRA_PRAYER_TIME = "extra_prayer_time"
        const val EXTRA_IS_PRE = "extra_is_pre"

        fun schedule(
            context: Context,
            timestamp: Long,
            prayerTimeMillis: Long,
            prayerName: String,
            isPre: Boolean,
            city: String,
            country: String,
        ) {
            val alarmIntent = Intent(context, CountdownAlarmReceiver::class.java).apply {
                action = ACTION
                putExtra(EXTRA_TIMESTAMP, timestamp)
                putExtra(EXTRA_PRAYER_TIME, prayerTimeMillis)
                putExtra(CountdownForegroundService.EXTRA_PRAYER_NAME, prayerName)
                putExtra(EXTRA_IS_PRE, isPre)
                putExtra(CountdownForegroundService.EXTRA_CITY, city)
                putExtra(CountdownForegroundService.EXTRA_COUNTRY, country)
            }
            val pending = PendingIntent.getBroadcast(
                context, REQUEST_CODE, alarmIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                    !am.canScheduleExactAlarms()
                ) {
                    throw SecurityException("Exact alarms not allowed")
                }
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timestamp, pending)
            } catch (_: Exception) {
                try {
                    am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timestamp, pending)
                } catch (_: Exception) {}
            }
        }

        fun cancel(context: Context) {
            val alarmIntent = Intent(context, CountdownAlarmReceiver::class.java).apply {
                action = ACTION
            }
            val pending = PendingIntent.getBroadcast(
                context, REQUEST_CODE, alarmIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            try {
                val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                am.cancel(pending)
            } catch (_: Exception) {}
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION) return
        val prayerTime = intent.getLongExtra(EXTRA_PRAYER_TIME, 0)
        if (prayerTime <= System.currentTimeMillis()) return
        val prayerName =
            intent.getStringExtra(CountdownForegroundService.EXTRA_PRAYER_NAME) ?: ""
        val isPre = intent.getBooleanExtra(EXTRA_IS_PRE, true)
        val city = intent.getStringExtra(CountdownForegroundService.EXTRA_CITY) ?: ""
        val country = intent.getStringExtra(CountdownForegroundService.EXTRA_COUNTRY) ?: ""

        val serviceIntent = Intent(context, CountdownForegroundService::class.java).apply {
            action = "start"
            putExtra(CountdownForegroundService.EXTRA_TARGET_TIME, prayerTime)
            putExtra(CountdownForegroundService.EXTRA_PRAYER_NAME, prayerName)
            putExtra(CountdownForegroundService.EXTRA_TITLE, prayerName)
            putExtra(CountdownForegroundService.EXTRA_CITY, city)
            putExtra(CountdownForegroundService.EXTRA_COUNTRY, country)
            putExtra(CountdownForegroundService.EXTRA_TYPE, if (isPre) "pre" else "post")
            putExtra(CountdownForegroundService.EXTRA_HEADER, "")
        }
        try {
            ContextCompat.startForegroundService(context, serviceIntent)
        } catch (_: Exception) {}
    }
}
