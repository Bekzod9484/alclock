package com.alclock.alclock

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar

class AlarmScheduler(private val context: Context) {
    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    fun scheduleAlarm(
        alarmId: String,
        scheduledTime: Long,
        soundName: String,
        isRepeating: Boolean,
        repeatDays: List<Int>
    ) {
        if (isRepeating && repeatDays.isNotEmpty) {
            // Schedule separate alarm for each weekday
            repeatDays.forEach { day ->
                val uniqueId = "${alarmId}_day_$day"
                scheduleSingleAlarm(uniqueId, scheduledTime, soundName, alarmId, day)
            }
        } else {
            // One-time alarm
            scheduleSingleAlarm(alarmId, scheduledTime, soundName, alarmId, null)
        }
    }

    private fun scheduleSingleAlarm(
        uniqueId: String,
        scheduledTime: Long,
        soundName: String,
        originalAlarmId: String,
        weekday: Int?
    ) {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = "TRIGGER_ALARM"
            putExtra("alarmId", originalAlarmId)
            putExtra("soundName", soundName)
            putExtra("weekday", weekday ?: -1)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            uniqueId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        )

        val calendar = Calendar.getInstance().apply {
            timeInMillis = scheduledTime
            if (weekday != null && weekday > 0) {
                // Convert weekday: 1=Monday, 7=Sunday to Calendar format: 2=Monday, 1=Sunday
                val calendarWeekday = when (weekday) {
                    1 -> Calendar.MONDAY
                    2 -> Calendar.TUESDAY
                    3 -> Calendar.WEDNESDAY
                    4 -> Calendar.THURSDAY
                    5 -> Calendar.FRIDAY
                    6 -> Calendar.SATURDAY
                    7 -> Calendar.SUNDAY
                    else -> Calendar.MONDAY
                }
                set(Calendar.DAY_OF_WEEK, calendarWeekday)
                
                // If this weekday has already passed this week, schedule for next week
                if (timeInMillis < System.currentTimeMillis()) {
                    add(Calendar.WEEK_OF_YEAR, 1)
                }
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                calendar.timeInMillis,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                calendar.timeInMillis,
                pendingIntent
            )
        }

        android.util.Log.d("AlarmScheduler", "✅ Scheduled alarm: $uniqueId at ${calendar.time}")
    }

    fun cancelAlarm(alarmId: String) {
        // Cancel all variants (one-time and all weekdays)
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = "TRIGGER_ALARM"
        }

        // Cancel one-time alarm
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        )
        alarmManager.cancel(pendingIntent)

        // Cancel all weekday variants
        for (day in 1..7) {
            val uniqueId = "${alarmId}_day_$day"
            val weekdayPendingIntent = PendingIntent.getBroadcast(
                context,
                uniqueId.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
            )
            alarmManager.cancel(weekdayPendingIntent)
        }

        android.util.Log.d("AlarmScheduler", "✅ Cancelled alarm: $alarmId")
    }

    fun cancelAllAlarms() {
        // This would require tracking all alarm IDs
        // For now, we'll rely on cancelling individual alarms
        android.util.Log.d("AlarmScheduler", "⚠️ cancelAllAlarms called - individual cancellation recommended")
    }

    fun scheduleSnooze(alarmId: String, scheduledTime: Long, soundName: String) {
        val snoozeId = "${alarmId}_snooze"
        scheduleSingleAlarm(snoozeId, scheduledTime, soundName, alarmId, null)
        android.util.Log.d("AlarmScheduler", "✅ Scheduled snooze: $snoozeId at ${java.util.Date(scheduledTime)}")
    }
}

