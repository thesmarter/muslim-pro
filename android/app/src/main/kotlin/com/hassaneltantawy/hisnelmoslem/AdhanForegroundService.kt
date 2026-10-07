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
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
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
        const val EXTRA_REPEAT = "extra_repeat"

        private var mediaPlayer: MediaPlayer? = null
        private var wakeLock: PowerManager.WakeLock? = null
        private const val TAG = "AdhanAudio"

        fun stopAndRelease(reason: String = "unspecified") {
            try {
                mediaPlayer?.apply {
                    Log.i(TAG, "stopAndRelease(reason=$reason, pos=${currentPosition}ms, dur=${duration}ms, playing=$isPlaying)")
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
                val repeat = intent?.getBooleanExtra(EXTRA_REPEAT, false) ?: false

                val notification = buildNotification(prayerName, muadhin)
                Log.i(TAG, "onStartCommand(muadhin=$muadhin, prayer=$prayerName, playSound=$playSound, repeat=$repeat)")
                startForeground(NOTIFICATION_ID, notification)
                if (playSound) {
                    playAdhan(muadhin, volume, repeat)
                }
            }
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        Log.i(TAG, "onDestroy")
        stopAndRelease("onDestroy")
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

    private fun loadMuadhinBitmap(@Suppress("UNUSED_PARAMETER") muadhinId: String): android.graphics.Bitmap? {
        // صورة واحدة ثابتة للجميع: شعار التطبيق من flutter_assets.
        return try {
            assets.open("flutter_assets/assets/images/app_icon.png").use { stream ->
                android.graphics.BitmapFactory.decodeStream(stream)
            }
        } catch (_: Exception) {
            Log.w(TAG, "App logo not found in flutter_assets")
            null
        }
    }

    private fun buildNotification(prayerName: String, muadhinId: String): Notification {
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

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("الأذان")
            .setContentText("وقت صلاة $prayerName")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(openPending)
            .addAction(android.R.drawable.ic_media_pause, "إيقاف", stopPending)

        // صورة المؤذن: أيقونة كبيرة + صورة موسعة عند سحب الإشعار.
        try {
            loadMuadhinBitmap(muadhinId)?.let { bitmap ->
                builder.setLargeIcon(bitmap)
                builder.setStyle(NotificationCompat.BigPictureStyle()
                    .bigPicture(bitmap)
                    .setSummaryText("وقت صلاة $prayerName"))
            }
        } catch (_: Exception) { /* الإشعار يعمل بدون صورة */ }

        return builder.build()
    }

    private fun playAdhan(muadhinId: String, volume: Float, repeat: Boolean) {
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Adhan:AudioLock")
            wakeLock?.acquire(10 * 60 * 1000L)

            // مصدر واحد فقط: flutter_assets — لا تكرار في res/raw.
            val assetPath = resolveAdhanAsset(muadhinId)
            if (assetPath == null) { stopSelf(); return }
            playAsset(assetPath, volume, repeat)
        } catch (e: Exception) {
            e.printStackTrace()
            stopSelf()
        }
    }

    private fun resolveAdhanAsset(muadhinId: String): String? {
        for (id in listOf(muadhinId, "wadie_alyamani")) {
            val path = "flutter_assets/assets/sounds/azhan/$id.mp3"
            try {
                assets.openFd(path).close()
                return path
            } catch (_: Exception) { /* جرّب البديل التالي */ }
        }
        Log.e(TAG, "No adhan asset found for $muadhinId")
        return null
    }

    private fun playAsset(assetPath: String, volume: Float, repeat: Boolean) {
        stopAndRelease("new-playback")

        val player = MediaPlayer().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )

            try {
                val afd = assets.openFd(assetPath)
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()
            } catch (_: Exception) {
                // احتياط للأصول المضغوطة: انسخ لملف كاش ثم شغّل بالمسار.
                val outFile = java.io.File(cacheDir, "adhan_playback.mp3")
                assets.open(assetPath).use { input ->
                    outFile.outputStream().use { output -> input.copyTo(output) }
                }
                setDataSource(outFile.absolutePath)
            }
            prepare()
            setVolume(volume, volume)

            // "تكرار الأذان حتى الإيقاف اليدوي": أعد التشغيل من البداية
            // بدل الإيقاف، ويبقى زر الإيقاف في الإشعار هو المخرج الوحيد.
            setOnCompletionListener {
                val pos = try { currentPosition } catch (_: Exception) { -1 }
                val dur = try { duration } catch (_: Exception) { -1 }
                Log.i(TAG, "onCompletion(pos=${pos}ms, dur=${dur}ms, repeat=$repeat)")
                if (repeat) {
                    try {
                        seekTo(0)
                        start()
                    } catch (_: Exception) {
                        stopSelf()
                    }
                } else {
                    stopSelf()
                }
            }
            setOnErrorListener { what, extra, _ ->
                Log.e(TAG, "onError(what=$what, extra=$extra)")
                stopSelf(); true
            }

            start()
        }
        mediaPlayer = player
    }
}
