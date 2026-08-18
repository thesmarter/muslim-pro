package com.detatech.Azkar

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import java.util.Locale

class CountdownForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "countdown_foreground_channel"
        const val NOTIFICATION_ID = 9000
        const val ACTION_STOP = "com.detatech.Azkar.action.STOP_COUNTDOWN"

        const val EXTRA_TARGET_TIME = "extra_target_time"
        const val EXTRA_PRAYER_NAME = "extra_prayer_name"
        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_CITY = "extra_city"
        const val EXTRA_COUNTRY = "extra_country"
        const val EXTRA_TYPE = "extra_type"
        const val EXTRA_HEADER = "extra_header"
    }

    private val handler = Handler(Looper.getMainLooper())
    private var wakeLock: PowerManager.WakeLock? = null
    private var targetTimeMillis: Long = 0
    private var prayerName: String = ""
    private var title: String = ""
    private var city: String = ""
    private var country: String = ""
    private var type: String = ""
    private var header: String = ""

    private val updateRunnable = object : Runnable {
        override fun run() {
            val now = System.currentTimeMillis()
            val remaining = targetTimeMillis - now

            if (remaining <= 0) {
                cancelNotification()
                stopSelf()
                return
            }

            updateNotification(remaining)
            handler.postDelayed(this, 1000)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                cancelNotification()
                stopSelf()
                return START_NOT_STICKY
            }
            else -> {
                targetTimeMillis = intent?.getLongExtra(EXTRA_TARGET_TIME, 0) ?: 0
                prayerName = intent?.getStringExtra(EXTRA_PRAYER_NAME) ?: ""
                title = intent?.getStringExtra(EXTRA_TITLE) ?: ""
                city = intent?.getStringExtra(EXTRA_CITY) ?: ""
                country = intent?.getStringExtra(EXTRA_COUNTRY) ?: ""
                type = intent?.getStringExtra(EXTRA_TYPE) ?: ""
                header = intent?.getStringExtra(EXTRA_HEADER) ?: ""

                if (targetTimeMillis <= 0) {
                    stopSelf()
                    return START_NOT_STICKY
                }

                acquireWakeLock()

                val notification = buildNotification(targetTimeMillis - System.currentTimeMillis())
                startForeground(NOTIFICATION_ID, notification)

                handler.removeCallbacks(updateRunnable)
                handler.post(updateRunnable)
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        handler.removeCallbacks(updateRunnable)
        releaseWakeLock()
        super.onDestroy()
    }

    private fun acquireWakeLock() {
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Countdown:TimerLock")
            wakeLock?.acquire(60 * 60 * 1000L) // max 1 hour
        } catch (_: Exception) {}
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) wakeLock?.release()
        } catch (_: Exception) {}
        wakeLock = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "عداد تنازلي",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "إشعارات العد التنازلي للصلوات"
                setSound(null, null)
                enableVibration(false)
                enableLights(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(remainingMillis: Long): Notification {
        val contentIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingContent = PendingIntent.getActivity(
            this, 0, contentIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(this, CountdownForegroundService::class.java).apply {
            action = ACTION_STOP
        }
        val pendingStop = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val displayHeader = header.ifEmpty { buildLocationDisplay() }
        val body = "$prayerName - ${formatRemaining(remainingMillis)}"

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(displayHeader)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(pendingContent)
            .setColor(Color.parseColor("#E53935"))
            .addAction(android.R.drawable.ic_delete, "إيقاف", pendingStop)
            .build()
    }

    private fun updateNotification(remainingMillis: Long) {
        val notification = buildNotification(remainingMillis)
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun cancelNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(NOTIFICATION_ID)
    }

    private fun buildLocationDisplay(): String {
        return when {
            city.isNotEmpty() && country.isNotEmpty() -> "$city - $country"
            city.isNotEmpty() -> city
            country.isNotEmpty() -> country
            else -> ""
        }
    }

    private fun formatRemaining(millis: Long): String {
        val totalSeconds = millis / 1000
        val hours = totalSeconds / 3600
        val minutes = (totalSeconds % 3600) / 60
        val seconds = totalSeconds % 60

        return if (hours > 0) {
            String.format(Locale.US, "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            String.format(Locale.US, "%02d:%02d", minutes, seconds)
        }
    }
}
