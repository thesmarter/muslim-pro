package com.detatech.Azkar

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Daily maintenance chain: fires shortly after midnight, launches a headless
 * Flutter engine that recomputes prayer times (which drift day by day through
 * the year) and re-registers every alarm/notification, then re-arms itself
 * for the next day. Also re-armed after boot from AdhanBootReceiver because
 * AlarmManager alarms do not survive power-off.
 */
class MaintenanceAlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "PrayerMaintenance"
        private const val ACTION = "com.detatech.Azkar.PRAYER_MAINTENANCE"
        private const val REQUEST_CODE = 9901
        private const val CHANNEL = "prayer_maintenance"
        private const val WATCHDOG_MS = 60_000L

        private val running = AtomicBoolean(false)

        fun scheduleNext(context: Context, timestampIfKnown: Long = 0) {
            val now = System.currentTimeMillis()
            var trigger = timestampIfKnown
            if (trigger <= now) trigger = defaultNextTrigger()

            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pi = pendingIntent(context)
            try {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pi)
            } catch (_: SecurityException) {
                try {
                    am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pi)
                } catch (_: Exception) {}
            }
        }

        private fun defaultNextTrigger(): Long {
            val cal = Calendar.getInstance()
            cal.add(Calendar.DAY_OF_MONTH, 1)
            cal.set(Calendar.HOUR_OF_DAY, 0)
            cal.set(Calendar.MINUTE, 5)
            cal.set(Calendar.SECOND, 0)
            cal.set(Calendar.MILLISECOND, 0)
            return cal.timeInMillis
        }

        private fun pendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, MaintenanceAlarmReceiver::class.java).apply {
                action = ACTION
            }
            return PendingIntent.getBroadcast(
                context, REQUEST_CODE, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION) return

        // Re-arm first so the daily chain survives even if the reschedule below fails.
        scheduleNext(context)

        if (!running.compareAndSet(false, true)) return
        val pendingResult = goAsync()
        val mainHandler = Handler(Looper.getMainLooper())
        var engine: FlutterEngine? = null
        var finished = false

        fun finish() {
            if (finished) return
            finished = true
            running.set(false)
            try { pendingResult.finish() } catch (_: Exception) {}
            engine?.let { e ->
                mainHandler.post {
                    try { e.destroy() } catch (_: Exception) {}
                }
            }
        }

        mainHandler.post {
            try {
                val flutterEngine = FlutterEngine(context)
                engine = flutterEngine
                MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                    .setMethodCallHandler { call, _ ->
                        if (call.method == "done") finish()
                    }
                flutterEngine.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint(
                        FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                        "prayerMaintenanceMain"
                    )
                )
                mainHandler.postDelayed({ finish() }, WATCHDOG_MS)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to launch maintenance engine", e)
                finish()
            }
        }
    }
}
