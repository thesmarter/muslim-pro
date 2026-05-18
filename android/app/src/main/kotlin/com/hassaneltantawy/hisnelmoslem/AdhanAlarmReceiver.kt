package com.detatech.Azkar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val muadhin = intent.getStringExtra(AdhanForegroundService.EXTRA_MUADHIN) ?: "wadie_alyamani"
        val prayerName = intent.getStringExtra(AdhanForegroundService.EXTRA_PRAYER_NAME) ?: ""
        val volume = intent.getFloatExtra(AdhanForegroundService.EXTRA_VOLUME, 0.5f)

        val serviceIntent = Intent(context, AdhanForegroundService::class.java).apply {
            putExtra(AdhanForegroundService.EXTRA_MUADHIN, muadhin)
            putExtra(AdhanForegroundService.EXTRA_PRAYER_NAME, prayerName)
            putExtra(AdhanForegroundService.EXTRA_VOLUME, volume)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}
