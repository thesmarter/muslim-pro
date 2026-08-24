package com.detatech.Azkar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.TimeZone

/**
 * Runs on BOOT_COMPLETED before flutter_local_notifications'
 * ScheduledNotificationBootReceiver (this filter has higher priority and
 * BOOT_COMPLETED is an ordered broadcast). The plugin re-registers cached
 * one-shot alarms with their original timestamp, and AlarmManager fires
 * past timestamps immediately, so all notifications missed while the
 * device was powered off would burst at boot. Here we remove expired
 * one-shot entries and roll recurring ones forward to their next real
 * occurrence so nothing fires outside its scheduled moment.
 */
class MissedNotificationsPurgeReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "MissedNotifPurge"

        // Must match FlutterLocalNotificationsPlugin storage:
        // SharedPreferences file/key = "scheduled_notifications".
        private const val PREFS_FILE = "scheduled_notifications"
        private const val PREFS_KEY = "scheduled_notifications"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED &&
            action != "android.intent.action.QUICKBOOT_POWERON" &&
            action != "com.htc.intent.action.QUICKBOOT_POWERON"
        ) {
            return
        }
        try {
            purge(context)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to purge missed notifications", e)
        }
    }

    private fun purge(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
        val json = prefs.getString(PREFS_KEY, null) ?: return
        val arr = JSONArray(json)

        val now = System.currentTimeMillis()
        val out = JSONArray()
        var removed = 0
        var forwarded = 0

        for (i in 0 until arr.length()) {
            val obj = arr.optJSONObject(i) ?: continue
            if (isRecurring(obj)) {
                if (forwardRecurring(obj)) forwarded++
                out.put(obj)
            } else {
                val trigger = triggerMillis(obj)
                if (trigger != null && trigger <= now) {
                    removed++
                } else {
                    out.put(obj)
                }
            }
        }

        if (removed > 0 || forwarded > 0) {
            prefs.edit().putString(PREFS_KEY, out.toString()).apply()
            Log.i(TAG, "Purged $removed missed one-shot notification(s), forwarded $forwarded recurring")
        }
    }

    private fun isRecurring(obj: JSONObject): Boolean =
        hasValue(obj, "matchDateTimeComponents") ||
            hasValue(obj, "repeatInterval") ||
            hasValue(obj, "repeatIntervalMilliseconds") ||
            hasValue(obj, "scheduledNotificationRepeatFrequency")

    private fun hasValue(obj: JSONObject, key: String): Boolean =
        obj.has(key) && !obj.isNull(key)

    private fun triggerMillis(obj: JSONObject): Long? {
        val zoneStr = obj.optString("timeZoneName", "")
        if (zoneStr.isEmpty()) return null
        return millisFromLocal(obj.optString("scheduledDateTime", ""), TimeZone.getTimeZone(zoneStr))
    }

    /**
     * Advances a missed recurring notification (daily time or weekly
     * dayOfWeekAndTime) to its next future occurrence, mirroring the
     * plugin's own reschedule logic. Returns true if modified.
     */
    private fun forwardRecurring(obj: JSONObject): Boolean {
        val comp = obj.optString("matchDateTimeComponents", "")
        if (comp != "time" && comp != "dayOfWeekAndTime") return false

        val zoneStr = obj.optString("timeZoneName", "")
        if (zoneStr.isEmpty()) return false
        val zone = TimeZone.getTimeZone(zoneStr)

        val stored = obj.optString("scheduledDateTime", "")
        val original = millisFromLocal(stored, zone) ?: return false
        if (original > System.currentTimeMillis()) return false

        val fields = parseLocalFields(stored) ?: return false

        val cal = Calendar.getInstance(zone)
        cal.clear()
        val today = Calendar.getInstance(zone)
        cal.set(
            today.get(Calendar.YEAR),
            today.get(Calendar.MONTH),
            today.get(Calendar.DAY_OF_MONTH),
            fields[3], fields[4], fields[5]
        )
        cal.set(Calendar.MILLISECOND, 0)

        while (cal.timeInMillis <= System.currentTimeMillis()) {
            cal.add(Calendar.DAY_OF_MONTH, 1)
        }

        if (comp == "dayOfWeekAndTime") {
            val originalCal = Calendar.getInstance(zone)
            originalCal.clear()
            originalCal.timeInMillis = original
            val targetDow = originalCal.get(Calendar.DAY_OF_WEEK)
            while (cal.get(Calendar.DAY_OF_WEEK) != targetDow) {
                cal.add(Calendar.DAY_OF_MONTH, 1)
            }
        }

        obj.put("scheduledDateTime", formatIsoLocal(cal))
        return true
    }

    private fun millisFromLocal(dateStr: String, zone: TimeZone): Long? {
        val fields = parseLocalFields(dateStr) ?: return null
        return try {
            val cal = Calendar.getInstance(zone)
            cal.clear()
            cal.set(fields[0], fields[1] - 1, fields[2], fields[3], fields[4], fields[5])
            cal.set(Calendar.MILLISECOND, 0)
            cal.timeInMillis
        } catch (_: Exception) {
            null
        }
    }

    /** Parses "yyyy-MM-ddTHH:mm" / "yyyy-MM-ddTHH:mm:ss" / with fractional seconds. */
    private fun parseLocalFields(dateStr: String): List<Int>? {
        if (dateStr.isEmpty()) return null
        return try {
            val parts = dateStr.split("T")
            if (parts.size != 2) return null
            val dateBits = parts[0].split("-")
            val timeBits = parts[1].split(":")
            if (dateBits.size != 3 || timeBits.size < 2) return null
            val second = if (timeBits.size >= 3) timeBits[2].substringBefore('.').toInt() else 0
            listOf(
                dateBits[0].toInt(),
                dateBits[1].toInt(),
                dateBits[2].toInt(),
                timeBits[0].toInt(),
                timeBits[1].toInt(),
                second
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun formatIsoLocal(cal: Calendar): String {
        fun two(v: Int) = v.toString().padStart(2, '0')
        return "${cal.get(Calendar.YEAR)}-${two(cal.get(Calendar.MONTH) + 1)}-" +
            "${two(cal.get(Calendar.DAY_OF_MONTH))}T" +
            "${two(cal.get(Calendar.HOUR_OF_DAY))}:${two(cal.get(Calendar.MINUTE))}:" +
            two(cal.get(Calendar.SECOND))
    }
}
