package com.nextalarm.next_alarm.alarm

import android.content.Context

object AlarmPrefs {
    private const val PREFS_NAME = "next_alarm_android"
    private const val KEY_ALARMS_JSON = "alarms_json"
    private const val KEY_PENDING_RINGING_ALARM_ID = "pending_ringing_alarm_id"

    fun getAlarmsJson(context: Context): String {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString(KEY_ALARMS_JSON, "[]") ?: "[]"
    }

    fun setAlarmsJson(context: Context, json: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_ALARMS_JSON, json).apply()
    }

    fun setPendingRingingAlarmId(context: Context, alarmId: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_PENDING_RINGING_ALARM_ID, alarmId).apply()
    }

    fun consumePendingRingingAlarmId(context: Context): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val alarmId = prefs.getString(KEY_PENDING_RINGING_ALARM_ID, null)
        if (!alarmId.isNullOrBlank()) {
            prefs.edit().remove(KEY_PENDING_RINGING_ALARM_ID).apply()
            return alarmId
        }
        return null
    }

    fun peekPendingRingingAlarmId(context: Context): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString(KEY_PENDING_RINGING_ALARM_ID, null)
    }

    fun clearPendingRingingAlarmId(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().remove(KEY_PENDING_RINGING_ALARM_ID).apply()
    }
}
