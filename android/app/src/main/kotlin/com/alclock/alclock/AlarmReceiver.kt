package com.alclock.alclock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            "TRIGGER_ALARM" -> {
                val alarmId = intent.getStringExtra("alarmId") ?: ""
                val soundName = intent.getStringExtra("soundName") ?: "alarm1"
                val weekday = intent.getIntExtra("weekday", -1)
                
                android.util.Log.d("AlarmReceiver", "🔔 Alarm triggered: $alarmId, sound: $soundName, weekday: $weekday")
                
                // Acquire wake lock to ensure device stays awake
                val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                val wakeLock = pm.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                    "AlClock::AlarmWakeLock"
                )
                wakeLock.acquire(10 * 60 * 1000L /*10 minutes*/)
                
                // Start foreground service to play alarm
                val serviceIntent = Intent(context, AlarmService::class.java).apply {
                    putExtra("alarmId", alarmId)
                    putExtra("soundName", soundName)
                    putExtra("weekday", weekday)
                }
                
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
                
                // Open full-screen alarm activity
                val alarmActivityIntent = Intent(context, AlarmActivity::class.java).apply {
                    putExtra("alarmId", alarmId)
                    putExtra("soundName", soundName)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                context.startActivity(alarmActivityIntent)
            }
            "STOP_ALARM" -> {
                val stopIntent = Intent(context, AlarmService::class.java).apply {
                    action = "STOP"
                }
                context.stopService(stopIntent)
            }
        }
    }
}


