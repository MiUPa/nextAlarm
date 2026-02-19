package com.nextalarm.next_alarm

import android.app.AlarmManager
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent

import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import android.view.WindowManager
import com.nextalarm.next_alarm.alarm.AlarmPrefs
import com.nextalarm.next_alarm.alarm.AlarmReceiver
import com.nextalarm.next_alarm.alarm.AlarmRingingService
import com.nextalarm.next_alarm.alarm.AlarmScheduler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val alarmScheduler: AlarmScheduler by lazy {
		AlarmScheduler(applicationContext)
	}

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		cachePendingAlarmFromIntent(intent)
	}

	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		cachePendingAlarmFromIntent(intent)
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"syncAlarms" -> {
						val rawAlarms = call.argument<List<*>>("alarms").orEmpty()
						@Suppress("UNCHECKED_CAST")
						val alarms = rawAlarms.mapNotNull { it as? Map<String, Any?> }
						alarmScheduler.syncAlarms(alarms)
						result.success(true)
					}
					"rescheduleFromStorage" -> {
						alarmScheduler.rescheduleFromStorage()
						result.success(true)
					}
					"consumePendingRingingAlarmId" -> {
						result.success(AlarmPrefs.consumePendingRingingAlarmId(applicationContext))
					}
					"peekPendingRingingAlarmId" -> {
						result.success(AlarmPrefs.peekPendingRingingAlarmId(applicationContext))
					}
					"canScheduleExactAlarms" -> {
						result.success(canScheduleExactAlarms())
					}
					"openExactAlarmSettings" -> {
						result.success(openExactAlarmSettings())
					}
					"isIgnoringBatteryOptimizations" -> {
						result.success(isIgnoringBatteryOptimizations())
					}
					"openBatteryOptimizationSettings" -> {
						result.success(openBatteryOptimizationSettings())
					}
					"stopAlarmRinging" -> {
						stopAlarmService()
						AlarmPrefs.clearPendingRingingAlarmId(applicationContext)
						disableShowOverLockScreen()
						result.success(true)
					}
					else -> result.notImplemented()
				}
			}
	}

	private fun cachePendingAlarmFromIntent(intent: Intent?) {
		val alarmId = intent?.getStringExtra(AlarmReceiver.EXTRA_ALARM_ID)
		if (!alarmId.isNullOrBlank()) {
			AlarmPrefs.setPendingRingingAlarmId(applicationContext, alarmId)
			enableShowOverLockScreen()
		}
	}

	private fun enableShowOverLockScreen() {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
			setShowWhenLocked(true)
			setTurnScreenOn(true)
			val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
			keyguardManager.requestDismissKeyguard(this, null)
		} else {
			@Suppress("DEPRECATION")
			window.addFlags(
				WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
					WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
					WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
			)
		}
		window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
	}

	private fun disableShowOverLockScreen() {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
			setShowWhenLocked(false)
			setTurnScreenOn(false)
		} else {
			@Suppress("DEPRECATION")
			window.clearFlags(
				WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
					WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
					WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
			)
		}
		window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
	}

	private fun canScheduleExactAlarms(): Boolean {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
			return true
		}
		val manager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
		return manager.canScheduleExactAlarms()
	}

	private fun openExactAlarmSettings(): Boolean {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
			return true
		}
		return try {
			val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
				data = Uri.parse("package:$packageName")
				addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			}
			startActivity(intent)
			true
		} catch (error: Exception) {
			Log.w(TAG, "Failed to open exact alarm settings", error)
			false
		}
	}

	private fun isIgnoringBatteryOptimizations(): Boolean {
		val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
		return powerManager.isIgnoringBatteryOptimizations(packageName)
	}

	private fun openBatteryOptimizationSettings(): Boolean {
		return try {
			val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
				addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			}
			startActivity(intent)
			true
		} catch (error: Exception) {
			Log.w(TAG, "Failed to open battery optimization settings", error)
			false
		}
	}

	private fun stopAlarmService() {
		val intent = Intent(this, AlarmRingingService::class.java).apply {
			action = AlarmRingingService.ACTION_STOP
		}
		startService(intent)
	}

	companion object {
		private const val CHANNEL_NAME = "next_alarm/android_alarm"
		private const val TAG = "MainActivity"
	}
}
