package com.detatech.Azkar

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

class AdhanScheduler(private val context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("adhan_schedules", Context.MODE_PRIVATE)

    fun schedule(
        muadhin: String,
        prayerName: String,
        timestamp: Long,
        volume: Float,
        id: Int,
    ) {
        val json = prefs.getString("schedules", "[]") ?: "[]"
        val arr = JSONArray(json)

        val newArr = JSONArray()
        for (i in 0 until arr.length()) {
            if (arr.getJSONObject(i).getInt("id") != id) {
                newArr.put(arr.getJSONObject(i))
            }
        }
        val obj = JSONObject().apply {
            put("muadhin", muadhin)
            put("prayerName", prayerName)
            put("timestamp", timestamp)
            put("volume", volume.toDouble())
            put("id", id)
        }
        newArr.put(obj)
        prefs.edit().putString("schedules", newArr.toString()).apply()

        scheduleAlarm(muadhin, prayerName, timestamp, volume, id)
    }

    fun cancel(id: Int) {
        val json = prefs.getString("schedules", "[]") ?: "[]"
        val arr = JSONArray(json)
        val newArr = JSONArray()
        for (i in 0 until arr.length()) {
            if (arr.getJSONObject(i).getInt("id") != id) {
                newArr.put(arr.getJSONObject(i))
            }
        }
        prefs.edit().putString("schedules", newArr.toString()).apply()

        val alarmIntent = Intent(context, AdhanAlarmReceiver::class.java)
        val pending = PendingIntent.getBroadcast(
            context, id, alarmIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pending)
    }

    fun cancelAll() {
        val json = prefs.getString("schedules", "[]") ?: "[]"
        val arr = JSONArray(json)
        for (i in 0 until arr.length()) {
            val id = arr.getJSONObject(i).getInt("id")
            val alarmIntent = Intent(context, AdhanAlarmReceiver::class.java)
            val pending = PendingIntent.getBroadcast(
                context, id, alarmIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.cancel(pending)
        }
        prefs.edit().remove("schedules").apply()
    }

    private fun scheduleAlarm(
        muadhin: String,
        prayerName: String,
        timestamp: Long,
        volume: Float,
        id: Int,
    ) {
        val alarmIntent = Intent(context, AdhanAlarmReceiver::class.java).apply {
            putExtra(AdhanForegroundService.EXTRA_MUADHIN, muadhin)
            putExtra(AdhanForegroundService.EXTRA_PRAYER_NAME, prayerName)
            putExtra(AdhanForegroundService.EXTRA_VOLUME, volume)
        }
        val pending = PendingIntent.getBroadcast(
            context, id, alarmIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        try {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timestamp, pending)
        } catch (e: SecurityException) {
            try {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timestamp, pending)
            } catch (_: Exception) {}
        }
    }
}
