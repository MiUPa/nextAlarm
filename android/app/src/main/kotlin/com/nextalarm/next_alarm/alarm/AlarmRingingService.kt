package com.nextalarm.next_alarm.alarm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.nextalarm.next_alarm.R

class AlarmRingingService : Service() {
    private var ringtone: Ringtone? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var notificationId: Int = BASE_NOTIFICATION_ID
    private val loopHandler = Handler(Looper.getMainLooper())
    private val loopCheckRunnable = object : Runnable {
        override fun run() {
            ringtone?.let {
                if (!it.isPlaying) {
                    it.play()
                }
            }
            loopHandler.postDelayed(this, LOOP_CHECK_INTERVAL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> stopAlarmAndSelf()
            else -> startRinging(intent)
        }
        return START_REDELIVER_INTENT
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopRingtone()
        stopVibration()
        releaseWakeLock()
        super.onDestroy()
    }

    private fun startRinging(intent: Intent?) {
        val alarmId = intent?.getStringExtra(AlarmReceiver.EXTRA_ALARM_ID) ?: return
        val label = intent.getStringExtra(AlarmReceiver.EXTRA_ALARM_LABEL).orEmpty()
        val sound = intent.getIntExtra(AlarmReceiver.EXTRA_ALARM_SOUND, 0)
        val vibrate = intent.getBooleanExtra(AlarmReceiver.EXTRA_ALARM_VIBRATE, true)
        val vibrationIntensity = intent.getIntExtra(AlarmReceiver.EXTRA_ALARM_VIBRATION_INTENSITY, 1)
        AlarmPrefs.setPendingRingingAlarmId(this, alarmId)

        notificationId = BASE_NOTIFICATION_ID + (alarmId.hashCode() and 0x0fffffff)
        val notification = buildNotification(alarmId, label)
        startForeground(notificationId, notification)
        acquireWakeLock()
        launchAlarmUi(alarmId, label)

        // AlarmSound.silent index == 5 in Dart enum
        if (sound != SOUND_SILENT) {
            startRingtone()
        }
        if (vibrate) {
            startVibration(vibrationIntensity)
        }
    }

    private fun launchAlarmUi(alarmId: String, label: String) {
        val launchIntent = Intent(this, AlarmRingingActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(AlarmReceiver.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmReceiver.EXTRA_ALARM_LABEL, label)
        }
        try {
            startActivity(launchIntent)
        } catch (error: Exception) {
            Log.w(TAG, "Failed to launch alarm UI from service", error)
        }
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "$packageName:alarm-ringing",
        ).apply {
            setReferenceCounted(false)
            acquire(WAKE_LOCK_TIMEOUT_MS)
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        wakeLock = null
    }

    private fun buildNotification(alarmId: String, label: String): Notification {
        val fullScreenIntent = Intent(this, AlarmRingingActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(AlarmReceiver.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmReceiver.EXTRA_ALARM_LABEL, label)
        }
        val fullScreenPendingIntent = PendingIntent.getActivity(
            this,
            alarmId.hashCode(),
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(getString(R.string.app_name))
            .setContentText(if (label.isBlank()) "Alarm is ringing" else label)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            // Sound and vibration are handled manually with USAGE_ALARM
            .setSound(null)
            .setVibrate(null)
            .setSilent(true)
            .build()
    }

    private fun startRingtone() {
        stopRingtone()
        val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        ringtone = RingtoneManager.getRingtone(this, alarmUri)?.apply {
            audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                isLooping = true
            }
            play()
        }
        // For pre-API 28 devices that lack Ringtone.isLooping, poll and restart
        // the ringtone when it finishes to achieve seamless looping.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            loopHandler.postDelayed(loopCheckRunnable, LOOP_CHECK_INTERVAL_MS)
        }
    }

    private fun stopRingtone() {
        loopHandler.removeCallbacks(loopCheckRunnable)
        ringtone?.stop()
        ringtone = null
    }

    /**
     * @param intensityIndex  VibrationIntensity enum index from Dart:
     *                        0 = gentle, 1 = standard, 2 = aggressive
     */
    private fun startVibration(intensityIndex: Int = 1) {
        stopVibration()
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        // Aggressive repeating pattern: rapid bursts, pauses, slams.
        // Format: [wait, vibrate, wait, vibrate, ...] in milliseconds.
        // Repeats from index 0.
        val pattern = longArrayOf(
            // Rapid bursts
            0, 100, 50, 100, 50, 200, 100, 100,
            // Strong slam
            200, 500, 100, 300,
            // Brief pause then staccato
            400, 80, 40, 80, 40, 80, 40, 80, 40, 80,
            // Final sustained buzz
            200, 600, 100, 400,
        )

        // Scale amplitude based on intensity: gentle=40%, standard=70%, aggressive=100%
        val scale = when (intensityIndex) {
            0 -> 0.4
            1 -> 0.7
            else -> 1.0
        }
        // Amplitudes: even indices = pause (0), odd indices = vibrate (scaled)
        val amplitudes = IntArray(pattern.size) { i ->
            if (i % 2 == 0) 0 else (255 * scale).toInt().coerceIn(1, 255)
        }

        val alarmAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(
                VibrationEffect.createWaveform(pattern, amplitudes, 0),
                alarmAttributes,
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, 0)
        }
    }

    private fun stopVibration() {
        vibrator?.cancel()
        vibrator = null
    }

    private fun stopAlarmAndSelf() {
        AlarmPrefs.clearPendingRingingAlarmId(this)
        stopRingtone()
        stopVibration()
        releaseWakeLock()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Alarm Ringing",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Channel for alarm ringing and full-screen alarm UI"
            lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            // Disable channel-level sound and vibration — we handle both
            // manually via Ringtone and Vibrator with USAGE_ALARM attributes
            // so they bypass DND and work with Bluetooth audio.
            setSound(null, null)
            enableVibration(false)
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        const val ACTION_START = "com.nextalarm.next_alarm.ALARM_RINGING_START"
        const val ACTION_STOP = "com.nextalarm.next_alarm.ALARM_RINGING_STOP"
        private const val CHANNEL_ID = "alarm_ringing_channel"
        private const val BASE_NOTIFICATION_ID = 42000
        private const val SOUND_SILENT = 5 // AlarmSound.silent index in Dart enum
        private const val LOOP_CHECK_INTERVAL_MS = 1000L
        private const val WAKE_LOCK_TIMEOUT_MS = 30 * 60 * 1000L
        private const val TAG = "AlarmRingingService"
    }
}
