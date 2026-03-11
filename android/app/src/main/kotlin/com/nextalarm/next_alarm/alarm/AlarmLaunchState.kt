package com.nextalarm.next_alarm.alarm

object AlarmLaunchState {
    const val EXTRA_LAUNCH_SOURCE = "alarm_launch_source"

    const val SOURCE_SERVICE_DIRECT = "service_direct"
    const val SOURCE_APP_FOREGROUND = "app_foreground"
    const val SOURCE_NOTIFICATION_FULLSCREEN = "notification_fullscreen"
    const val SOURCE_NOTIFICATION_TAP = "notification_tap"
    const val SOURCE_NOTIFICATION_ACTION = "notification_action"
    const val SOURCE_NOTIFICATION_ONLY = "notification_only"
}
