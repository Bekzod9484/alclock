package com.alclock.alclock

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
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
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        
        // Acquire wake lock
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "AlClock::AlarmServiceWakeLock"
        )
        
        // Create AudioFocusRequest for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            
            audioFocusRequest = AudioFocusRequest.Builder(AudioFocusRequest.AUDIOFOCUS_GAIN)
                .setAudioAttributes(audioAttributes)
                .setAcceptsDelayedFocusGain(true)
                .setOnAudioFocusChangeListener { focusChange ->
                    when (focusChange) {
                        AudioManager.AUDIOFOCUS_LOSS_TRANSIENT,
                        AudioManager.AUDIOFOCUS_LOSS -> {
                            // Don't stop alarm even if focus is lost
                            android.util.Log.d("AlarmService", "Audio focus lost, but continuing alarm")
                        }
                        AudioManager.AUDIOFOCUS_GAIN -> {
                            android.util.Log.d("AlarmService", "Audio focus gained")
                        }
                    }
                }
                .build()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        android.util.Log.d("AlarmService", "🔔 onStartCommand called")
        
        if (intent?.action == "STOP") {
            android.util.Log.d("AlarmService", "   → STOP action received, stopping service")
            stopSelf()
            return START_NOT_STICKY
        }

        val soundName = intent?.getStringExtra("soundName") ?: "alarm1"
        val alarmId = intent?.getStringExtra("alarmId") ?: ""

        android.util.Log.d("AlarmService", "🔔🔔🔔 STARTING ALARM SERVICE 🔔🔔🔔")
        android.util.Log.d("AlarmService", "   Alarm ID: $alarmId")
        android.util.Log.d("AlarmService", "   Sound: $soundName")

        wakeLock?.acquire(10 * 60 * 1000L /*10 minutes*/)
        android.util.Log.d("AlarmService", "✅ Wake lock acquired")
        
        startForeground(NOTIFICATION_ID, createNotification(alarmId))
        android.util.Log.d("AlarmService", "✅ Foreground service started")
        
        startAlarmSound(soundName)
        android.util.Log.d("AlarmService", "✅ Alarm sound started")
        
        startVibration()
        android.util.Log.d("AlarmService", "✅ Vibration started")

        // Open full-screen alarm activity
        // CRITICAL: Use flags to ensure it appears above lock screen
        val alarmIntent = Intent(this, AlarmActivity::class.java).apply {
            putExtra("alarmId", alarmId)
            putExtra("soundName", soundName)
            // CRITICAL: These flags ensure activity appears above lock screen
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or
                    Intent.FLAG_ACTIVITY_NO_HISTORY
        }
        android.util.Log.d("AlarmService", "🔔 Starting AlarmActivity from service")
        startActivity(alarmIntent)
        android.util.Log.d("AlarmService", "✅ AlarmActivity started from service")

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
            android.util.Log.d("AlarmService", "🔊 startAlarmSound called with soundName: $soundName")
            stopAlarmSound()

            // Request audio focus first
            val focusResult = requestAudioFocus()
            android.util.Log.d("AlarmService", "   Audio focus result: $focusResult")
            if (focusResult != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
                android.util.Log.w("AlarmService", "⚠️ Audio focus not granted, but continuing anyway")
            }

            val resourceId = resources.getIdentifier(
                soundName,
                "raw",
                packageName
            )
            
            android.util.Log.d("AlarmService", "   Looking for resource: $soundName in package: $packageName")
            android.util.Log.d("AlarmService", "   Resource ID found: $resourceId")

            if (resourceId != 0) {
                // Create MediaPlayer with AudioAttributes for Android 5.0+
                mediaPlayer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    val audioAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED)
                        .build()
                    
                    MediaPlayer().apply {
                        setAudioAttributes(audioAttributes)
                        setDataSource(applicationContext, android.net.Uri.parse("android.resource://$packageName/$resourceId"))
                        prepare()
                    }
                } else {
                    @Suppress("DEPRECATION")
                    MediaPlayer.create(this, resourceId)
                }
                
                mediaPlayer?.apply {
                    isLooping = true
                    setVolume(1.0f, 1.0f)
                    setWakeMode(applicationContext, PowerManager.PARTIAL_WAKE_LOCK)
                    start()
                }
                android.util.Log.d("AlarmService", "✅ Playing alarm sound: $soundName (resourceId: $resourceId)")
            } else {
                android.util.Log.e("AlarmService", "❌ Sound resource not found: $soundName")
                // Try default alarm1
                val defaultResourceId = resources.getIdentifier("alarm1", "raw", packageName)
                if (defaultResourceId != 0) {
                    mediaPlayer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        val audioAttributes = AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED)
                            .build()
                        
                        MediaPlayer().apply {
                            setAudioAttributes(audioAttributes)
                            setDataSource(applicationContext, android.net.Uri.parse("android.resource://$packageName/$defaultResourceId"))
                            prepare()
                        }
                    } else {
                        @Suppress("DEPRECATION")
                        MediaPlayer.create(this, defaultResourceId)
                    }
                    
                    mediaPlayer?.apply {
                        isLooping = true
                        setVolume(1.0f, 1.0f)
                        setWakeMode(applicationContext, PowerManager.PARTIAL_WAKE_LOCK)
                        start()
                    }
                    android.util.Log.d("AlarmService", "✅ Playing default alarm sound: alarm1")
                } else {
                    android.util.Log.e("AlarmService", "❌ Default alarm sound also not found!")
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("AlarmService", "❌ Error playing alarm sound", e)
        }
    }
    
    private fun requestAudioFocus(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && audioFocusRequest != null) {
            audioManager?.requestAudioFocus(audioFocusRequest!!) ?: AudioManager.AUDIOFOCUS_REQUEST_FAILED
        } else {
            @Suppress("DEPRECATION")
            audioManager?.requestAudioFocus(
                null,
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN
            ) ?: AudioManager.AUDIOFOCUS_REQUEST_FAILED
        }
    }
    
    private fun abandonAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && audioFocusRequest != null) {
            audioManager?.abandonAudioFocusRequest(audioFocusRequest!!)
        } else {
            @Suppress("DEPRECATION")
            audioManager?.abandonAudioFocus(null)
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
        abandonAudioFocus()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Alarm Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alarm is ringing"
                setSound(null, null) // No sound in notification, we play it directly via MediaPlayer
                // Set audio attributes for alarm usage
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val audioAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                    setAudioAttributes(audioAttributes)
                }
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

        // Full-screen intent for alarm activity (appears above lock screen)
        val fullScreenIntent = Intent(this, AlarmActivity::class.java).apply {
            putExtra("alarmId", alarmId)
            putExtra("soundName", intent?.getStringExtra("soundName") ?: "alarm1")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val fullScreenPendingIntent = PendingIntent.getActivity(
            this,
            0,
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Alarm")
            .setContentText("Alarm is ringing")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(fullScreenPendingIntent, true) // CRITICAL: Shows full-screen UI
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


