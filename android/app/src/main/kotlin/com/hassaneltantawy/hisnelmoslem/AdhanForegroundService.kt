package com.detatech.Azkar

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class AdhanForegroundService : Service() {
    companion object {
        const val CHANNEL_ID = "adhan_foreground_service"
        const val NOTIFICATION_ID = 1001
        const val ACTION_STOP = "com.detatech.Azkar.action.STOP_ADHAN"
        const val EXTRA_MUADHIN = "extra_muadhin"
        const val EXTRA_PRAYER_NAME = "extra_prayer_name"
        const val EXTRA_VOLUME = "extra_volume"
        const val EXTRA_PLAY_SOUND = "extra_play_sound"

        private var mediaPlayer: MediaPlayer? = null
        private var wakeLock: PowerManager.WakeLock? = null

        fun stopAndRelease() {
            try {
                mediaPlayer?.apply {
                    if (isPlaying) stop()
                    release()
                }
                mediaPlayer = null
            } catch (_: Exception) {}
            releaseWakeLock()
        }

        private fun releaseWakeLock() {
            try {
                if (wakeLock?.isHeld == true) wakeLock?.release()
            } catch (_: Exception) {}
            wakeLock = null
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopSelf()
                return START_NOT_STICKY
            }
            else -> {
                val muadhin = intent?.getStringExtra(EXTRA_MUADHIN) ?: "wadie_alyamani"
                val prayerName = intent?.getStringExtra(EXTRA_PRAYER_NAME) ?: ""
                val volume = intent?.getFloatExtra(EXTRA_VOLUME, 0.5f) ?: 0.5f
                val playSound = intent?.getBooleanExtra(EXTRA_PLAY_SOUND, true) ?: true

                val notification = buildNotification(prayerName)
                startForeground(NOTIFICATION_ID, notification)
                if (playSound) {
                    playAdhan(muadhin, volume)
                }
            }
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopAndRelease()
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "الأذان",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "تشغيل الأذان في الخلفية"
            setSound(null, null)
            enableVibration(false)
        }
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(prayerName: String): Notification {
        val stopIntent = Intent(this, AdhanForegroundService::class.java).apply { action = ACTION_STOP }
        val stopPending = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val openIntent = packageManager.getLaunchIntentForPackage(packageName)
        val openPending = PendingIntent.getActivity(
            this, 1, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("الأذان")
            .setContentText("وقت صلاة $prayerName")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(openPending)
            .addAction(android.R.drawable.ic_media_pause, "إيقاف", stopPending)
            .build()
    }

    private fun playAdhan(muadhinId: String, volume: Float) {
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Adhan:AudioLock")
            wakeLock?.acquire(10 * 60 * 1000L)

            val resId = resources.getIdentifier(muadhinId, "raw", packageName)
            if (resId == 0) {
                val fallback = resources.getIdentifier("wadie_alyamani", "raw", packageName)
                if (fallback == 0) { stopSelf(); return }
                playResource(fallback, volume)
            } else {
                playResource(resId, volume)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            stopSelf()
        }
    }

    private fun playResource(resId: Int, volume: Float) {
        stopAndRelease()

        val player = MediaPlayer().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )

            setDataSource(applicationContext, Uri.parse("android.resource://$packageName/$resId"))
            prepare()
            setVolume(volume, volume)

            setOnCompletionListener { stopSelf() }
            setOnErrorListener { _, _, _ -> stopSelf(); true }

            start()
        }
        mediaPlayer = player
    }
}
