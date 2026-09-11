package com.detatech.Azkar

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
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Re-arms prayer alarms when the user changes the clock or time-zone.
 * Receives TIME_SET / TIMEZONE_CHANGED, then re-arms the daily
 * maintenance chain via MaintenanceAlarmReceiver.scheduleNext() and
 * launches the same headless prayerMaintenanceMain engine.
 */
class TimeChangeReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "PrayerMaintenance"
        private const val CHANNEL = "prayer_maintenance"
        private const val WATCHDOG_MS = 60_000L
        private val running = AtomicBoolean(false)
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action != Intent.ACTION_TIME_CHANGED &&
            action != Intent.ACTION_TIMEZONE_CHANGED
        ) return

        // Re-arm first so the daily chain survives even if the engine below fails.
        MaintenanceAlarmReceiver.scheduleNext(context)

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
                Log.e(TAG, "Failed to launch maintenance engine on time change", e)
                finish()
            }
        }
    }
}
