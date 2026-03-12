package com.nextalarm.next_alarm.alarm

import android.app.ActivityOptions
import android.os.Build
import android.os.Bundle

object PendingIntentOptions {
    fun backgroundActivityStart(): Bundle? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            return null
        }

        val mode = if (Build.VERSION.SDK_INT >= 36) {
            ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOW_ALWAYS
        } else {
            ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
        }

        return ActivityOptions.makeBasic()
            .setPendingIntentCreatorBackgroundActivityStartMode(mode)
            .toBundle()
    }
}
