package com.alclock.alclock

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity: FlutterActivity() {
    private val SCHEDULER_CHANNEL = "alclock/alarm_scheduler"
    private val PLAYER_CHANNEL = "alclock/alarm_player"
    private val SCREEN_STATE_CHANNEL = "alclock/screen_state"
    private lateinit var alarmScheduler: AlarmScheduler
    private var screenStateListener: ScreenStateListener? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        alarmScheduler = AlarmScheduler(applicationContext)

        // Alarm Scheduler Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCHEDULER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val alarmId = call.argument<String>("alarmId") ?: ""
                    val scheduledTime = call.argument<Long>("scheduledTime") ?: 0L
                    val soundName = call.argument<String>("soundName") ?: "alarm1"
                    val isRepeating = call.argument<Boolean>("isRepeating") ?: false
                    val repeatDays = call.argument<List<Int>>("repeatDays") ?: emptyList()

                    try {
                        alarmScheduler.scheduleAlarm(alarmId, scheduledTime, soundName, isRepeating, repeatDays)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SCHEDULE_ERROR", e.message, null)
                    }
                }
                "cancelAlarm" -> {
                    val alarmId = call.argument<String>("alarmId") ?: ""
                    try {
                        alarmScheduler.cancelAlarm(alarmId)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CANCEL_ERROR", e.message, null)
                    }
                }
                "cancelAllAlarms" -> {
                    try {
                        alarmScheduler.cancelAllAlarms()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CANCEL_ALL_ERROR", e.message, null)
                    }
                }
                "scheduleSnooze" -> {
                    val args = call.arguments as? Map<String, Any>
                    val alarmId = args?.get("alarmId") as? String ?: ""
                    val scheduledTime = args?.get("scheduledTime") as? Long ?: 0L
                    val soundName = args?.get("soundName") as? String ?: "alarm1"
                    try {
                        alarmScheduler.scheduleSnooze(alarmId, scheduledTime, soundName)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SNOOZE_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Alarm Player Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PLAYER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAlarm" -> {
                    val args = call.arguments as? Map<String, Any>
                    val soundName = args?.get("soundName") as? String ?: "alarm1"
                    try {
                        val intent = Intent(this, AlarmService::class.java).apply {
                            putExtra("soundName", soundName)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("START_ERROR", e.message, null)
                    }
                }
                "stopAlarm" -> {
                    try {
                        val intent = Intent(this, AlarmService::class.java).apply {
                            action = "STOP"
                        }
                        stopService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("STOP_ERROR", e.message, null)
                    }
                }
                "isPlaying" -> {
                    // Check if alarm service is running
                    result.success(false) // Simplified - can be enhanced
                }
                else -> result.notImplemented()
            }
        }

        // Screen State Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_STATE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> {
                    screenStateListener = ScreenStateListener(flutterEngine.dartExecutor.binaryMessenger, SCREEN_STATE_CHANNEL)
                    screenStateListener?.start()
                    result.success(true)
                }
                "stopListening" -> {
                    screenStateListener?.stop()
                    screenStateListener = null
                    result.success(true)
                }
                "isScreenOn" -> {
                    val isScreenOn = screenStateListener?.isScreenOn() ?: true
                    result.success(isScreenOn)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        screenStateListener?.onScreenOn()
    }

    override fun onPause() {
        super.onPause()
        screenStateListener?.onScreenOff()
    }
}

class ScreenStateListener(
    private val messenger: io.flutter.plugin.common.BinaryMessenger,
    private val channel: String
) {
    private var isListening = false
    private var isScreenOn = true

    fun start() {
        isListening = true
        isScreenOn = true
    }

    fun stop() {
        isListening = false
    }

    fun onScreenOn() {
        if (isListening && !isScreenOn) {
            isScreenOn = true
            notifyScreenState(true)
        }
    }

    fun onScreenOff() {
        if (isListening && isScreenOn) {
            isScreenOn = false
            notifyScreenState(false)
        }
    }

    fun isScreenOn(): Boolean {
        return isScreenOn
    }

    private fun notifyScreenState(isOn: Boolean) {
        val methodChannel = MethodChannel(messenger, channel)
        methodChannel.invokeMethod("onScreenStateChanged", isOn)
    }
}
