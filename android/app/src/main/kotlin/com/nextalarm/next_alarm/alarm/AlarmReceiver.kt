package com.nextalarm.next_alarm.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_TRIGGER) return

        val alarmId = intent.getStringExtra(EXTRA_ALARM_ID)
        if (alarmId.isNullOrBlank()) return

        val label = intent.getStringExtra(EXTRA_ALARM_LABEL) ?: ""
        val sound = intent.getIntExtra(EXTRA_ALARM_SOUND, 0)
        val vibrate = intent.getBooleanExtra(EXTRA_ALARM_VIBRATE, true)
        val vibrationIntensity = intent.getIntExtra(EXTRA_ALARM_VIBRATION_INTENSITY, 1)
        val scheduler = AlarmScheduler(context)
        scheduler.rescheduleAlarmById(alarmId)
        AlarmPrefs.setPendingRingingAlarmId(context, alarmId)

        val ringingUiIntent = Intent(context, AlarmRingingActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_ALARM_ID, alarmId)
            putExtra(EXTRA_ALARM_LABEL, label)
        }
        try {
            context.startActivity(ringingUiIntent)
        } catch (error: RuntimeException) {
            Log.w(TAG, "Failed to launch ringing activity from receiver", error)
        }

        val serviceIntent = Intent(context, AlarmRingingService::class.java).apply {
            action = AlarmRingingService.ACTION_START
            putExtra(EXTRA_ALARM_ID, alarmId)
            putExtra(EXTRA_ALARM_LABEL, label)
            putExtra(EXTRA_ALARM_SOUND, sound)
            putExtra(EXTRA_ALARM_VIBRATE, vibrate)
            putExtra(EXTRA_ALARM_VIBRATION_INTENSITY, vibrationIntensity)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        // Full-screen notification intents are best-effort on modern Android,
        // so we also attempt to launch the alarm activity directly.
        // If the OS blocks background launch, the foreground notification still
        // remains as a fallback path to open the alarm UI.
        try {
            val activityIntent = Intent(context, AlarmRingingActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(EXTRA_ALARM_ID, alarmId)
                putExtra(EXTRA_ALARM_LABEL, label)
            }
            context.startActivity(activityIntent)
        } catch (error: Exception) {
            Log.w(TAG, "Failed to launch AlarmRingingActivity directly", error)
        }

        Log.i(TAG, "Alarm triggered: $alarmId")
    }

    companion object {
        const val ACTION_TRIGGER = "com.nextalarm.next_alarm.ALARM_TRIGGER"
        const val EXTRA_ALARM_ID = "alarm_id"
        const val EXTRA_ALARM_LABEL = "alarm_label"
        const val EXTRA_ALARM_SOUND = "alarm_sound"
        const val EXTRA_ALARM_VIBRATE = "alarm_vibrate"
        const val EXTRA_ALARM_VIBRATION_INTENSITY = "alarm_vibration_intensity"
        private const val TAG = "AlarmReceiver"
    }
}
