package com.nextalarm.next_alarm.alarm

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import com.nextalarm.next_alarm.MainActivity

class AlarmRingingActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val alarmId = intent.getStringExtra(AlarmReceiver.EXTRA_ALARM_ID)
        if (!alarmId.isNullOrBlank()) {
            AlarmPrefs.setPendingRingingAlarmId(this, alarmId)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(AlarmReceiver.EXTRA_ALARM_ID, alarmId)
            putExtra(
                AlarmReceiver.EXTRA_ALARM_LABEL,
                intent.getStringExtra(AlarmReceiver.EXTRA_ALARM_LABEL),
            )
        }
        startActivity(launchIntent)
        finish()
    }
}
