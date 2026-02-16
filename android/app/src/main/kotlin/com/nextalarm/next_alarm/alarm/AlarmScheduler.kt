package com.nextalarm.next_alarm.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.nextalarm.next_alarm.MainActivity
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

class AlarmScheduler(private val context: Context) {
    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    data class AlarmPayload(
        val id: String,
        val hour: Int,
        val minute: Int,
        val isEnabled: Boolean,
        val repeatDays: Set<Int>,
        val label: String,
        val sound: Int, // AlarmSound enum index from Dart (5 = silent)
        val vibrate: Boolean,
    )

    fun syncAlarms(rawAlarms: List<Map<String, Any?>>) {
        val previous = loadAlarmsFromStorage()
        previous.forEach { cancelAlarmInternal(it.id) }

        val alarms = rawAlarms.mapNotNull { mapToAlarmPayload(it) }
        persistAlarms(rawAlarms)

        alarms.filter { it.isEnabled }.forEach { scheduleAlarmInternal(it) }
    }

    fun rescheduleFromStorage() {
        val alarms = loadAlarmsFromStorage()
        alarms.filter { it.isEnabled }.forEach { scheduleAlarmInternal(it) }
    }

    fun rescheduleAlarmById(alarmId: String) {
        val alarm = loadAlarmsFromStorage().firstOrNull { it.id == alarmId } ?: return
        if (alarm.isEnabled) {
            scheduleAlarmInternal(alarm)
        }
    }

    private fun persistAlarms(rawAlarms: List<Map<String, Any?>>) {
        val jsonArray = JSONArray()
        rawAlarms.forEach { jsonArray.put(JSONObject(it)) }
        AlarmPrefs.setAlarmsJson(context, jsonArray.toString())
    }

    private fun loadAlarmsFromStorage(): List<AlarmPayload> {
        return try {
            val json = AlarmPrefs.getAlarmsJson(context)
            val array = JSONArray(json)
            buildList {
                for (i in 0 until array.length()) {
                    val item = array.optJSONObject(i) ?: continue
                    parseAlarm(item)?.let { add(it) }
                }
            }
        } catch (error: Exception) {
            Log.w(TAG, "Failed to parse stored alarms", error)
            emptyList()
        }
    }

    private fun parseAlarm(item: JSONObject): AlarmPayload? {
        val id = item.optString("id")
        if (id.isNullOrBlank()) return null

        val repeatArray = item.optJSONArray("repeatDays") ?: JSONArray()
        val repeatDays = buildSet {
            for (i in 0 until repeatArray.length()) {
                val value = repeatArray.optInt(i, -1)
                if (value in 1..7) add(value)
            }
        }

        return AlarmPayload(
            id = id,
            hour = item.optInt("hour", 0),
            minute = item.optInt("minute", 0),
            isEnabled = item.optBoolean("isEnabled", true),
            repeatDays = repeatDays,
            label = item.optString("label", ""),
            sound = item.optInt("sound", 0),
            vibrate = item.optBoolean("vibrate", true),
        )
    }

    private fun mapToAlarmPayload(item: Map<String, Any?>): AlarmPayload? {
        val id = item["id"] as? String ?: return null
        val hour = (item["hour"] as? Number)?.toInt() ?: return null
        val minute = (item["minute"] as? Number)?.toInt() ?: return null
        val isEnabled = item["isEnabled"] as? Boolean ?: true
        val label = item["label"] as? String ?: ""

        @Suppress("UNCHECKED_CAST")
        val repeatRaw = (item["repeatDays"] as? List<Any?>).orEmpty()
        val repeatDays = repeatRaw.mapNotNull {
            (it as? Number)?.toInt()?.takeIf { day -> day in 1..7 }
        }.toSet()

        val sound = (item["sound"] as? Number)?.toInt() ?: 0
        val vibrate = item["vibrate"] as? Boolean ?: true

        return AlarmPayload(
            id = id,
            hour = hour,
            minute = minute,
            isEnabled = isEnabled,
            repeatDays = repeatDays,
            label = label,
            sound = sound,
            vibrate = vibrate,
        )
    }

    private fun scheduleAlarmInternal(alarm: AlarmPayload) {
        val triggerAtMillis = calculateNextTriggerAtMillis(alarm)
        val requestCode = requestCode(alarm.id)
        val alarmIntent = Intent(context, AlarmReceiver::class.java).apply {
            action = AlarmReceiver.ACTION_TRIGGER
            putExtra(AlarmReceiver.EXTRA_ALARM_ID, alarm.id)
            putExtra(AlarmReceiver.EXTRA_ALARM_LABEL, alarm.label)
            putExtra(AlarmReceiver.EXTRA_ALARM_SOUND, alarm.sound)
            putExtra(AlarmReceiver.EXTRA_ALARM_VIBRATE, alarm.vibrate)
        }
        val alarmPendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            alarmIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val showIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(AlarmReceiver.EXTRA_ALARM_ID, alarm.id)
            putExtra(AlarmReceiver.EXTRA_ALARM_LABEL, alarm.label)
        }
        val showPendingIntent = PendingIntent.getActivity(
            context,
            requestCode,
            showIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        try {
            alarmManager.setAlarmClock(
                AlarmManager.AlarmClockInfo(triggerAtMillis, showPendingIntent),
                alarmPendingIntent,
            )
            Log.i(TAG, "Scheduled alarm ${alarm.id} at $triggerAtMillis")
        } catch (securityError: SecurityException) {
            // Fallback when exact alarm cannot be scheduled.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    alarmPendingIntent,
                )
            } else {
                alarmManager.set(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    alarmPendingIntent,
                )
            }
            Log.w(TAG, "Scheduled in fallback mode for ${alarm.id}", securityError)
        }
    }

    private fun cancelAlarmInternal(alarmId: String) {
        val requestCode = requestCode(alarmId)
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = AlarmReceiver.ACTION_TRIGGER
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }

    private fun calculateNextTriggerAtMillis(alarm: AlarmPayload): Long {
        val now = Calendar.getInstance()
        val next = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, alarm.hour)
            set(Calendar.MINUTE, alarm.minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        if (!next.after(now)) {
            next.add(Calendar.DAY_OF_YEAR, 1)
        }

        if (alarm.repeatDays.isNotEmpty()) {
            while (!alarm.repeatDays.contains(calendarToAlarmWeekday(next.get(Calendar.DAY_OF_WEEK)))) {
                next.add(Calendar.DAY_OF_YEAR, 1)
            }
        }

        return next.timeInMillis
    }

    private fun calendarToAlarmWeekday(calendarDay: Int): Int {
        return when (calendarDay) {
            Calendar.MONDAY -> 1
            Calendar.TUESDAY -> 2
            Calendar.WEDNESDAY -> 3
            Calendar.THURSDAY -> 4
            Calendar.FRIDAY -> 5
            Calendar.SATURDAY -> 6
            Calendar.SUNDAY -> 7
            else -> 7
        }
    }

    private fun requestCode(alarmId: String): Int = alarmId.hashCode() and 0x7fffffff

    companion object {
        private const val TAG = "AlarmScheduler"
    }
}
