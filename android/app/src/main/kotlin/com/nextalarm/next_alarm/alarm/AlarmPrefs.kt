package com.nextalarm.next_alarm.alarm

import android.content.Context

object AlarmPrefs {
    private const val PREFS_NAME = "next_alarm_android"
    private const val KEY_ALARMS_JSON = "alarms_json"
    private const val KEY_PENDING_RINGING_ALARM_ID = "pending_ringing_alarm_id"
    private const val KEY_LAST_LAUNCH_SOURCE = "last_alarm_launch_source"
    private const val KEY_LAST_LAUNCH_AT_MS = "last_alarm_launch_at_ms"
    private const val KEY_LAST_LAUNCH_ALARM_ID = "last_alarm_launch_alarm_id"
    private const val KEY_SILENCE_AFTER_MINUTES = "silence_after_minutes"

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

    fun setLastAlarmLaunchSource(context: Context, source: String, alarmId: String?) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(KEY_LAST_LAUNCH_SOURCE, source)
            .putLong(KEY_LAST_LAUNCH_AT_MS, System.currentTimeMillis())
            .apply()

        if (!alarmId.isNullOrBlank()) {
            prefs.edit().putString(KEY_LAST_LAUNCH_ALARM_ID, alarmId).apply()
        }
    }

    fun getLastAlarmLaunchSource(context: Context): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString(KEY_LAST_LAUNCH_SOURCE, null)
    }

    fun getLastAlarmLaunchAtMs(context: Context): Long? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return if (prefs.contains(KEY_LAST_LAUNCH_AT_MS)) {
            prefs.getLong(KEY_LAST_LAUNCH_AT_MS, 0L)
        } else {
            null
        }
    }

    fun getLastAlarmLaunchAlarmId(context: Context): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString(KEY_LAST_LAUNCH_ALARM_ID, null)
    }

    fun setSilenceAfterMinutes(context: Context, minutes: Int?) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        if (minutes == null || minutes <= 0) {
            editor.remove(KEY_SILENCE_AFTER_MINUTES)
        } else {
            editor.putInt(KEY_SILENCE_AFTER_MINUTES, minutes)
        }
        editor.apply()
    }

    fun getSilenceAfterMinutes(context: Context): Int? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return if (prefs.contains(KEY_SILENCE_AFTER_MINUTES)) {
            prefs.getInt(KEY_SILENCE_AFTER_MINUTES, 0)
        } else {
            null
        }
    }
}
