package com.detatech.Azkar

import com.ryanheise.audioservice.AudioServiceActivity
import android.view.KeyEvent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

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
