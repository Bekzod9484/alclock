package com.alclock.alclock

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class AlarmActivity : FlutterActivity() {
    private val CHANNEL = "alclock/alarm_trigger"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        android.util.Log.d("AlarmActivity", "🔔 AlarmActivity onCreate called")
        
        // CRITICAL: Make full-screen and show over lock screen
        // This ensures alarm appears even when phone is locked
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            android.util.Log.d("AlarmActivity", "✅ setShowWhenLocked(true) and setTurnScreenOn(true) called")
        }
        
        // CRITICAL: Add flags for ALL Android versions
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_FULLSCREEN or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )
        
        android.util.Log.d("AlarmActivity", "✅ Window flags set for lock screen display")
    }
    
    override fun onResume() {
        super.onResume()
        // Ensure screen stays on when activity resumes
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
    
    override fun onNewIntent(Intent intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Handle new alarm intent (e.g., when another alarm triggers while this one is showing)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAlarmData" -> {
                    val alarmId = intent.getStringExtra("alarmId") ?: ""
                    val soundName = intent.getStringExtra("soundName") ?: "alarm1"
                    result.success(mapOf(
                        "alarmId" to alarmId,
                        "soundName" to soundName
                    ))
                }
                else -> result.notImplemented()
            }
        }
    }
}


