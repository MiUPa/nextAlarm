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
        val scheduler = AlarmScheduler(context)
        scheduler.rescheduleAlarmById(alarmId)
        AlarmPrefs.setPendingRingingAlarmId(context, alarmId)

        val serviceIntent = Intent(context, AlarmRingingService::class.java).apply {
            action = AlarmRingingService.ACTION_START
            putExtra(EXTRA_ALARM_ID, alarmId)
            putExtra(EXTRA_ALARM_LABEL, label)
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
        private const val TAG = "AlarmReceiver"
    }
}
