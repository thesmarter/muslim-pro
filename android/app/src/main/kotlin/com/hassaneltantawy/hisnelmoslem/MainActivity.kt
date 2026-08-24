package com.detatech.Azkar

import com.ryanheise.audioservice.AudioServiceActivity
import android.content.Intent
import android.view.KeyEvent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.core.content.ContextCompat

class MainActivity : AudioServiceActivity() {
    private lateinit var volumeChannel: MethodChannel
    private var activateVolumeDispatch: Boolean = false
    private var adhanScheduler: AdhanScheduler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        volumeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "volume_button_channel")
        volumeChannel.setMethodCallHandler { call, _ ->
            if (call.method == "activate_volumeBtn") {
                activateVolumeDispatch = call.arguments as Boolean
            }
        }

        adhanScheduler = AdhanScheduler(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "adhan_scheduler")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        val args = call.arguments as Map<*, *>
                        adhanScheduler?.schedule(
                            muadhin = args["muadhin"] as String,
                            prayerName = args["prayerName"] as String,
                            timestamp = (args["timestamp"] as Number).toLong(),
                            volume = (args["volume"] as Number).toFloat(),
                            id = (args["id"] as Number).toInt(),
                        )
                        result.success(true)
                    }
                    "cancel" -> {
                        adhanScheduler?.cancel((call.arguments as Number).toInt())
                        result.success(true)
                    }
                    "cancelAll" -> {
                        adhanScheduler?.cancelAll()
                        result.success(true)
                    }
                    "scheduleMaintenance" -> {
                        val args = call.arguments as Map<*, *>
                        MaintenanceAlarmReceiver.scheduleNext(
                            this@MainActivity,
                            (args["timestamp"] as Number).toLong()
                        )
                        result.success(true)
                    }
                    "stopAdhan" -> {
                        val stopIntent = Intent(this@MainActivity, AdhanForegroundService::class.java).apply {
                            action = AdhanForegroundService.ACTION_STOP
                        }
                        startService(stopIntent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "countdown_service")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startCountdown" -> {
                        val args = call.arguments as Map<*, *>
                        val intent = Intent(this@MainActivity, CountdownForegroundService::class.java).apply {
                            action = "start"
                            putExtra(
                                CountdownForegroundService.EXTRA_TARGET_TIME,
                                (args["targetTimeMillis"] as Number).toLong()
                            )
                            putExtra(CountdownForegroundService.EXTRA_PRAYER_NAME, args["prayerName"] as? String ?: "")
                            putExtra(CountdownForegroundService.EXTRA_TITLE, args["title"] as? String ?: "")
                            putExtra(CountdownForegroundService.EXTRA_CITY, args["city"] as? String ?: "")
                            putExtra(CountdownForegroundService.EXTRA_COUNTRY, args["country"] as? String ?: "")
                            putExtra(CountdownForegroundService.EXTRA_TYPE, args["type"] as? String ?: "")
                        }
                        ContextCompat.startForegroundService(this@MainActivity, intent)
                        result.success(true)
                    }
                    "stopCountdown" -> {
                        val intent = Intent(this@MainActivity, CountdownForegroundService::class.java).apply {
                            action = CountdownForegroundService.ACTION_STOP
                        }
                        startService(intent)
                        result.success(true)
                    }
                    "isRunning" -> {
                        result.success(false)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val action: Int = event.getAction()
        val keyCode: Int = event.getKeyCode()
        if (!activateVolumeDispatch) {
            return super.dispatchKeyEvent(event)
        }
        return when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP -> {
                if (action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
                    volumeChannel.invokeMethod("volumeBtnPressed", "VOLUME_UP_DOWN")
                } else if (action == KeyEvent.ACTION_UP) {
                    volumeChannel.invokeMethod("volumeBtnPressed", "VOLUME_UP_UP")
                }
                true
            }
            KeyEvent.KEYCODE_VOLUME_DOWN -> {
                if (action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
                    volumeChannel.invokeMethod("volumeBtnPressed", "VOLUME_DOWN_DOWN")
                } else if (action == KeyEvent.ACTION_UP) {
                    volumeChannel.invokeMethod("volumeBtnPressed", "VOLUME_DOWN_UP")
                }
                true
            }
            else -> super.dispatchKeyEvent(event)
        }
    }
}
