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
        val scheduler = AlarmScheduler(context)
        scheduler.rescheduleAlarmById(alarmId)
        AlarmPrefs.setPendingRingingAlarmId(context, alarmId)

        val serviceIntent = Intent(context, AlarmRingingService::class.java).apply {
            action = AlarmRingingService.ACTION_START
            putExtra(EXTRA_ALARM_ID, alarmId)
            putExtra(EXTRA_ALARM_LABEL, label)
            putExtra(EXTRA_ALARM_SOUND, sound)
            putExtra(EXTRA_ALARM_VIBRATE, vibrate)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        Log.i(TAG, "Alarm triggered: $alarmId")
    }

    companion object {
        const val ACTION_TRIGGER = "com.nextalarm.next_alarm.ALARM_TRIGGER"
        const val EXTRA_ALARM_ID = "alarm_id"
        const val EXTRA_ALARM_LABEL = "alarm_label"
        const val EXTRA_ALARM_SOUND = "alarm_sound"
        const val EXTRA_ALARM_VIBRATE = "alarm_vibrate"
        private const val TAG = "AlarmReceiver"
    }
}
