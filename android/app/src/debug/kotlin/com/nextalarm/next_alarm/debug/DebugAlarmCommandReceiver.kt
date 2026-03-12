package com.nextalarm.next_alarm.debug

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import com.nextalarm.next_alarm.alarm.AlarmReceiver
import com.nextalarm.next_alarm.alarm.AlarmRingingService

class DebugAlarmCommandReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_TRIGGER -> startAlarmService(context, intent)
            ACTION_STOP -> stopAlarmService(context)
        }
    }

    private fun startAlarmService(context: Context, intent: Intent) {
        val alarmId = intent.getStringExtra(AlarmReceiver.EXTRA_ALARM_ID)
            ?.takeIf { it.isNotBlank() }
            ?: DEFAULT_ALARM_ID
        val label = intent.getStringExtra(AlarmReceiver.EXTRA_ALARM_LABEL).orEmpty()
        val sound = intent.getIntExtra(AlarmReceiver.EXTRA_ALARM_SOUND, DEFAULT_SOUND)
        val vibrate = intent.getBooleanExtra(AlarmReceiver.EXTRA_ALARM_VIBRATE, DEFAULT_VIBRATE)
        val vibrationIntensity = intent.getIntExtra(
            AlarmReceiver.EXTRA_ALARM_VIBRATION_INTENSITY,
            DEFAULT_VIBRATION_INTENSITY,
        )

        val serviceIntent = Intent(context, AlarmRingingService::class.java).apply {
            action = AlarmRingingService.ACTION_START
            putExtra(AlarmReceiver.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmReceiver.EXTRA_ALARM_LABEL, label)
            putExtra(AlarmReceiver.EXTRA_ALARM_SOUND, sound)
            putExtra(AlarmReceiver.EXTRA_ALARM_VIBRATE, vibrate)
            putExtra(AlarmReceiver.EXTRA_ALARM_VIBRATION_INTENSITY, vibrationIntensity)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }

    private fun stopAlarmService(context: Context) {
        val serviceIntent = Intent(context, AlarmRingingService::class.java).apply {
            action = AlarmRingingService.ACTION_STOP
        }
        context.startService(serviceIntent)
    }

    companion object {
        const val ACTION_TRIGGER = "com.nextalarm.next_alarm.DEBUG_TRIGGER_ALARM"
        const val ACTION_STOP = "com.nextalarm.next_alarm.DEBUG_STOP_ALARM"

        private const val DEFAULT_ALARM_ID = "debug-alarm"
        private const val DEFAULT_SOUND = 0
        private const val DEFAULT_VIBRATE = false
        private const val DEFAULT_VIBRATION_INTENSITY = 1
    }
}
