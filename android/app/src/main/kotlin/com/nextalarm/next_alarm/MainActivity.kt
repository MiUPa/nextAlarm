package com.nextalarm.next_alarm

import android.app.AlarmManager
import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent

import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import android.view.WindowManager
import androidx.core.app.NotificationManagerCompat
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
		applyAlarmWindowBehavior(intent)
		cachePendingAlarmFromIntent(intent)
	}

	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		applyAlarmWindowBehavior(intent)
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
					"canUseFullScreenIntent" -> {
						result.success(canUseFullScreenIntent())
					}
					"openFullScreenIntentSettings" -> {
						result.success(openFullScreenIntentSettings())
					}
					"areNotificationsEnabled" -> {
						result.success(areNotificationsEnabled())
					}
					"openNotificationSettings" -> {
						result.success(openNotificationSettings())
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
						clearAlarmWindowBehavior()
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
		}
	}

	private fun applyAlarmWindowBehavior(intent: Intent?) {
		val alarmId = intent?.getStringExtra(AlarmReceiver.EXTRA_ALARM_ID)
		if (alarmId.isNullOrBlank()) return

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
			setShowWhenLocked(true)
			setTurnScreenOn(true)
			val keyguardManager = getSystemService(KeyguardManager::class.java)
			keyguardManager?.requestDismissKeyguard(this, null)
		} else {
			@Suppress("DEPRECATION")
			window.addFlags(
				WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
					WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
					WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD,
			)
		}
		window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
	}

	private fun clearAlarmWindowBehavior() {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
			setShowWhenLocked(false)
			setTurnScreenOn(false)
		} else {
			@Suppress("DEPRECATION")
			window.clearFlags(
				WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
					WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
					WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD,
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

	private fun canUseFullScreenIntent(): Boolean {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
			return true
		}
		val manager = getSystemService(NotificationManager::class.java)
		return manager?.canUseFullScreenIntent() ?: false
	}

	private fun openFullScreenIntentSettings(): Boolean {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
			return true
		}
		return try {
			val intent = Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
				data = Uri.parse("package:$packageName")
				addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			}
			startActivity(intent)
			true
		} catch (error: Exception) {
			Log.w(TAG, "Failed to open full-screen intent settings", error)
			openAppDetailsSettings()
		}
	}

	private fun areNotificationsEnabled(): Boolean {
		return NotificationManagerCompat.from(applicationContext).areNotificationsEnabled()
	}

	private fun openNotificationSettings(): Boolean {
		return try {
			val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
				putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
				addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			}
			startActivity(intent)
			true
		} catch (error: Exception) {
			Log.w(TAG, "Failed to open notification settings", error)
			openAppDetailsSettings()
		}
	}

	private fun openAppDetailsSettings(): Boolean {
		return try {
			val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
				data = Uri.parse("package:$packageName")
				addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			}
			startActivity(intent)
			true
		} catch (error: Exception) {
			Log.w(TAG, "Failed to open app details settings", error)
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
