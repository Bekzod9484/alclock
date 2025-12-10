package com.alclock.alclock

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import androidx.core.app.NotificationCompat
import java.io.IOException

class AlarmService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private val CHANNEL_ID = "alarm_channel"
    private val NOTIFICATION_ID = 1
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        
        // Acquire wake lock
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "AlClock::AlarmServiceWakeLock"
        )
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP") {
            stopSelf()
            return START_NOT_STICKY
        }

        val soundName = intent?.getStringExtra("soundName") ?: "alarm1"
        val alarmId = intent?.getStringExtra("alarmId") ?: ""

        wakeLock?.acquire(10 * 60 * 1000L /*10 minutes*/)
        
        startForeground(NOTIFICATION_ID, createNotification(alarmId))
        startAlarmSound(soundName)
        startVibration()

        // Open full-screen alarm activity
        val alarmIntent = Intent(this, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("alarmId", alarmId)
            putExtra("soundName", soundName)
        }
        startActivity(alarmIntent)

        return START_STICKY
    }
    
    private fun startVibration() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(
                VibrationEffect.createWaveform(
                    longArrayOf(0, 500, 500),
                    0
                )
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(longArrayOf(0, 500, 500), 0)
        }
    }
    
    private fun stopVibration() {
        vibrator?.cancel()
    }

    private fun startAlarmSound(soundName: String) {
        try {
            stopAlarmSound()

            val resourceId = resources.getIdentifier(
                soundName,
                "raw",
                packageName
            )

            if (resourceId != 0) {
                mediaPlayer = MediaPlayer.create(this, resourceId)
                mediaPlayer?.apply {
                    isLooping = true
                    setVolume(1.0f, 1.0f)
                    setWakeMode(applicationContext, PowerManager.PARTIAL_WAKE_LOCK)
                    start()
                }
                android.util.Log.d("AlarmService", "✅ Playing alarm sound: $soundName")
            } else {
                android.util.Log.e("AlarmService", "❌ Sound resource not found: $soundName")
                // Try default alarm1
                val defaultResourceId = resources.getIdentifier("alarm1", "raw", packageName)
                if (defaultResourceId != 0) {
                    mediaPlayer = MediaPlayer.create(this, defaultResourceId)
                    mediaPlayer?.apply {
                        isLooping = true
                        setVolume(1.0f, 1.0f)
                        setWakeMode(applicationContext, PowerManager.PARTIAL_WAKE_LOCK)
                        start()
                    }
                }
            }
        } catch (e: IOException) {
            android.util.Log.e("AlarmService", "❌ Error playing alarm sound", e)
        }
    }

    fun stopAlarmSound() {
        mediaPlayer?.apply {
            if (isPlaying) {
                stop()
            }
            release()
        }
        mediaPlayer = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Alarm Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alarm is ringing"
                setSound(null, null) // No sound in notification, we play it directly
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(alarmId: String): Notification {
        val stopIntent = Intent(this, AlarmReceiver::class.java).apply {
            action = "STOP_ALARM"
            putExtra("alarmId", alarmId)
        }
        val stopPendingIntent = PendingIntent.getBroadcast(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Alarm")
            .setContentText("Alarm is ringing")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stopPendingIntent)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        stopAlarmSound()
        stopVibration()
        wakeLock?.release()
        wakeLock = null
    }
}


