package com.nextalarm.next_alarm.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (
            action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_LOCKED_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            AlarmScheduler(context).rescheduleFromStorage()
            Log.i(TAG, "Rescheduled alarms after action: $action")
        }
    }

    companion object {
        private const val TAG = "BootReceiver"
    }
}
