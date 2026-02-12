package com.nextalarm.next_alarm.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class TimeChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action == Intent.ACTION_TIME_CHANGED || action == Intent.ACTION_TIMEZONE_CHANGED) {
            AlarmScheduler(context).rescheduleFromStorage()
            Log.i(TAG, "Rescheduled alarms after action: $action")
        }
    }

    companion object {
        private const val TAG = "TimeChangeReceiver"
    }
}
