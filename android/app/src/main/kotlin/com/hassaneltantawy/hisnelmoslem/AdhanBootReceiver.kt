package com.detatech.Azkar

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray

class AdhanBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            rescheduleAll(context)
            // AlarmManager alarms do not survive power-off, so re-arm the
            // daily prayer-times maintenance chain after boot as well.
            MaintenanceAlarmReceiver.scheduleNext(context)
        }
    }

    private fun rescheduleAll(context: Context) {
        val prefs = context.getSharedPreferences("adhan_schedules", Context.MODE_PRIVATE)
        val json = prefs.getString("schedules", "[]") ?: "[]"
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val now = System.currentTimeMillis()

        val arr = JSONArray(json)
        for (i in 0 until arr.length()) {
            val obj = arr.getJSONObject(i)
            val timestamp = obj.getLong("timestamp")
            if (timestamp > now) {
                val id = obj.getInt("id")
                val alarmIntent = Intent(context, AdhanAlarmReceiver::class.java).apply {
                    putExtra(AdhanForegroundService.EXTRA_MUADHIN, obj.getString("muadhin"))
                    putExtra(AdhanForegroundService.EXTRA_PRAYER_NAME, obj.getString("prayerName"))
                    putExtra(AdhanForegroundService.EXTRA_VOLUME, obj.getDouble("volume").toFloat())
                    putExtra(AdhanForegroundService.EXTRA_PLAY_SOUND, obj.optBoolean("playSound", true))
                }
                val pending = PendingIntent.getBroadcast(
                    context, id, alarmIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                try {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timestamp, pending)
                } catch (_: SecurityException) {
                    try {
                        alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timestamp, pending)
                    } catch (_: Exception) {}
                }
            }
        }
    }
}
