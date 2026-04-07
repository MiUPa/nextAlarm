package com.nextalarm.next_alarm.alarm

import android.app.Notification
import android.app.NotificationChannel
import android.app.KeyguardManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
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
import androidx.core.content.ContextCompat
import com.nextalarm.next_alarm.AlarmActivity
import com.nextalarm.next_alarm.R

class AlarmRingingService : Service() {
    private var ringtone: Ringtone? = null
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var serviceNotificationId: Int = BASE_NOTIFICATION_ID
    private var alertNotificationId: Int = BASE_NOTIFICATION_ID + ALERT_NOTIFICATION_OFFSET
    private val loopHandler = Handler(Looper.getMainLooper())
    private var activeAlarmId: String? = null
    private var activeSound: Int = SOUND_SILENT
    private var activeVibrate: Boolean = false
    private var activeVibrationIntensity: Int = 1
    private var activeGradualVolume: Boolean = false
    private var currentVolume: Float = MAX_VOLUME
    private var autoStopRunnable: Runnable? = null
    private var isScreenReceiverRegistered = false
    private val screenOffRecoveryRunnable = Runnable {
        if (!isAlarmActive()) return@Runnable
        Log.i(TAG, "Reasserting alarm playback after screen off")
        acquireWakeLock()
        ensurePlaybackActive()
        if (activeVibrate) {
            startVibration(activeVibrationIntensity)
        }
    }
    private val ringtoneMonitorRunnable = object : Runnable {
        override fun run() {
            if (!isAlarmActive()) {
                return
            }
            if (activeSound != SOUND_SILENT) {
                if (!isPlaybackActive()) {
                    Log.i(TAG, "Alarm playback stopped unexpectedly; restarting")
                    startPlayback()
                }
            }
            loopHandler.postDelayed(this, RINGTONE_MONITOR_INTERVAL_MS)
        }
    }
    private val volumeRampRunnable = object : Runnable {
        override fun run() {
            if (!isAlarmActive() || !activeGradualVolume) {
                return
            }

            val player = mediaPlayer ?: return
            if (!player.isPlaying) {
                return
            }

            if (currentVolume >= MAX_VOLUME) {
                return
            }

            currentVolume = (currentVolume + VOLUME_STEP).coerceAtMost(MAX_VOLUME)
            player.setVolume(currentVolume, currentVolume)
            Log.i(TAG, "Alarm volume increased to $currentVolume")

            if (currentVolume < MAX_VOLUME) {
                loopHandler.postDelayed(this, VOLUME_STEP_INTERVAL_MS)
            }
        }
    }
    private val vibrationLoopRunnable = object : Runnable {
        override fun run() {
            if (!isAlarmActive() || !activeVibrate) {
                return
            }
            playSingleVibrationCycle(activeVibrationIntensity)
            loopHandler.postDelayed(this, VIBRATION_PATTERN_DURATION_MS)
        }
    }
    private val screenStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != Intent.ACTION_SCREEN_OFF || !isAlarmActive()) {
                return
            }
            Log.i(TAG, "Screen turned off while alarm active")
            acquireWakeLock()
            loopHandler.removeCallbacks(screenOffRecoveryRunnable)
            loopHandler.postDelayed(screenOffRecoveryRunnable, SCREEN_OFF_RECOVERY_DELAY_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
        registerScreenStateReceiver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> stopAlarmAndSelf()
            else -> startRinging(intent)
        }
        return START_REDELIVER_INTENT
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onTaskRemoved(rootIntent: Intent?) {
        if (isAlarmActive()) {
            Log.i(TAG, "App task removed while alarm active; stopping playback")
            stopAlarmAndSelf()
        }
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        loopHandler.removeCallbacks(screenOffRecoveryRunnable)
        stopPlayback()
        stopVibration()
        releaseWakeLock()
        cancelAlertNotification()
        unregisterScreenStateReceiver()
        super.onDestroy()
    }

    private fun startRinging(intent: Intent?) {
        val alarmId = intent?.getStringExtra(AlarmReceiver.EXTRA_ALARM_ID) ?: return
        val label = intent.getStringExtra(AlarmReceiver.EXTRA_ALARM_LABEL).orEmpty()
        val sound = intent.getIntExtra(AlarmReceiver.EXTRA_ALARM_SOUND, 0)
        val vibrate = intent.getBooleanExtra(AlarmReceiver.EXTRA_ALARM_VIBRATE, true)
        val vibrationIntensity = intent.getIntExtra(AlarmReceiver.EXTRA_ALARM_VIBRATION_INTENSITY, 1)
        val gradualVolume = intent.getBooleanExtra(AlarmReceiver.EXTRA_ALARM_GRADUAL_VOLUME, false)
        activeAlarmId = alarmId
        activeSound = sound
        activeVibrate = vibrate
        activeVibrationIntensity = vibrationIntensity
        activeGradualVolume = gradualVolume && sound != SOUND_SILENT
        currentVolume = if (activeGradualVolume) INITIAL_VOLUME else MAX_VOLUME
        AlarmPrefs.setPendingRingingAlarmId(this, alarmId)
        stopPlayback()
        stopVibration()
        cancelAutoStop()

        serviceNotificationId = BASE_NOTIFICATION_ID + (alarmId.hashCode() and 0x0fffffff)
        alertNotificationId = serviceNotificationId + ALERT_NOTIFICATION_OFFSET
        startForeground(serviceNotificationId, buildForegroundNotification(label))
        postAlertNotification(alarmId, label)
        acquireWakeLock()
        maybeLaunchAlarmActivityDirectly(alarmId, label)
        AlarmPrefs.setLastAlarmLaunchSource(this, AlarmLaunchState.SOURCE_NOTIFICATION_ONLY, alarmId)
        scheduleAutoStop()

        // AlarmSound.silent index == 5 in Dart enum
        if (sound != SOUND_SILENT) {
            startPlayback()
        }
        if (vibrate) {
            startVibration(vibrationIntensity)
        }
    }

    private fun isAlarmActive(): Boolean = !activeAlarmId.isNullOrBlank()

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

    private fun buildForegroundNotification(label: String): Notification {
        val contentText = if (label.isBlank()) {
            "Alarm service is active"
        } else {
            "Alarm service is active for $label"
        }

        return NotificationCompat.Builder(this, FOREGROUND_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(getString(R.string.app_name))
            .setContentText(contentText)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .build()
    }

    private fun buildAlertNotification(alarmId: String, label: String): Notification {
        val tapIntent = Intent(this, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            putExtra(AlarmReceiver.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmReceiver.EXTRA_ALARM_LABEL, label)
            putExtra(
                AlarmLaunchState.EXTRA_LAUNCH_SOURCE,
                AlarmLaunchState.SOURCE_NOTIFICATION_TAP,
            )
        }
        val tapPendingIntent = PendingIntent.getActivity(
            this,
            alarmId.hashCode(),
            tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            PendingIntentOptions.backgroundActivityStart(),
        )

        val fullScreenIntent = Intent(this, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(AlarmReceiver.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmReceiver.EXTRA_ALARM_LABEL, label)
            putExtra(
                AlarmLaunchState.EXTRA_LAUNCH_SOURCE,
                AlarmLaunchState.SOURCE_NOTIFICATION_FULLSCREEN,
            )
        }
        val fullScreenPendingIntent = PendingIntent.getActivity(
            this,
            alarmId.hashCode() + 1,
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            PendingIntentOptions.backgroundActivityStart(),
        )

        val actionIntent = Intent(this, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(AlarmReceiver.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmReceiver.EXTRA_ALARM_LABEL, label)
            putExtra(
                AlarmLaunchState.EXTRA_LAUNCH_SOURCE,
                AlarmLaunchState.SOURCE_NOTIFICATION_ACTION,
            )
        }
        val actionPendingIntent = PendingIntent.getActivity(
            this,
            alarmId.hashCode() + 2,
            actionIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            PendingIntentOptions.backgroundActivityStart(),
        )

        return NotificationCompat.Builder(this, ALERT_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(getString(R.string.app_name))
            .setContentText(if (label.isBlank()) "Alarm is ringing" else label)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setContentIntent(tapPendingIntent)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .addAction(
                0,
                getString(R.string.open_alarm_action),
                actionPendingIntent,
            )
            .build()
    }

    private fun postAlertNotification(alarmId: String, label: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(alertNotificationId, buildAlertNotification(alarmId, label))
    }

    private fun maybeLaunchAlarmActivityDirectly(alarmId: String, label: String) {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        val screenOff = !powerManager.isInteractive
        val keyguardLocked = keyguardManager.isKeyguardLocked
        if (!screenOff && !keyguardLocked) {
            return
        }

        val launchIntent = Intent(this, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(AlarmReceiver.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmReceiver.EXTRA_ALARM_LABEL, label)
            putExtra(
                AlarmLaunchState.EXTRA_LAUNCH_SOURCE,
                AlarmLaunchState.SOURCE_SERVICE_DIRECT,
            )
        }

        try {
            startActivity(launchIntent)
        } catch (_: Exception) {
            // Keep the notification full-screen path as the fallback on devices
            // that reject direct background launches from a foreground service.
        }
    }

    private fun startPlayback() {
        if (activeSound == SOUND_SILENT) return

        val alarmUri = resolveAlarmUri(activeSound)
        if (alarmUri == null) {
            Log.w(TAG, "No ringtone URI resolved for sound index $activeSound")
            return
        }

        if (activeGradualVolume) {
            startMediaPlayer(alarmUri)
        } else {
            startRingtone(alarmUri)
        }
    }

    private fun startRingtone(alarmUri: Uri) {
        stopPlayback()
        currentVolume = MAX_VOLUME
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
        loopHandler.removeCallbacks(ringtoneMonitorRunnable)
        loopHandler.postDelayed(ringtoneMonitorRunnable, RINGTONE_MONITOR_INTERVAL_MS)
    }

    private fun startMediaPlayer(alarmUri: Uri) {
        stopPlayback()

        currentVolume = currentVolume.coerceIn(INITIAL_VOLUME, MAX_VOLUME)
        try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                setDataSource(this@AlarmRingingService, alarmUri)
                isLooping = true
                setVolume(currentVolume, currentVolume)
                prepare()
                start()
            }
        } catch (error: Exception) {
            Log.w(TAG, "Failed to start gradual alarm playback", error)
            mediaPlayer?.release()
            mediaPlayer = null
            currentVolume = MAX_VOLUME
            activeGradualVolume = false
            startRingtone(alarmUri)
            return
        }

        loopHandler.removeCallbacks(volumeRampRunnable)
        if (currentVolume < MAX_VOLUME) {
            loopHandler.postDelayed(volumeRampRunnable, VOLUME_STEP_INTERVAL_MS)
        }
        loopHandler.removeCallbacks(ringtoneMonitorRunnable)
        loopHandler.postDelayed(ringtoneMonitorRunnable, RINGTONE_MONITOR_INTERVAL_MS)
    }

    private fun ensurePlaybackActive() {
        if (activeSound == SOUND_SILENT) return
        if (!isPlaybackActive()) {
            startPlayback()
        }
    }

    private fun isPlaybackActive(): Boolean {
        val currentPlayer = mediaPlayer
        if (currentPlayer != null) {
            return runCatching { currentPlayer.isPlaying }.getOrDefault(false)
        }

        val currentRingtone = ringtone
        return currentRingtone?.isPlaying == true
    }

    private fun stopPlayback() {
        loopHandler.removeCallbacks(ringtoneMonitorRunnable)
        loopHandler.removeCallbacks(volumeRampRunnable)
        ringtone?.stop()
        ringtone = null
        runCatching { mediaPlayer?.stop() }
        runCatching { mediaPlayer?.release() }
        mediaPlayer = null
    }

    /**
     * @param intensityIndex  VibrationIntensity enum index from Dart:
     *                        0 = gentle, 1 = standard, 2 = aggressive
     */
    private fun startVibration(intensityIndex: Int = 1) {
        stopVibration()
        activeVibrate = true
        activeVibrationIntensity = intensityIndex
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        playSingleVibrationCycle(intensityIndex)
        loopHandler.postDelayed(vibrationLoopRunnable, VIBRATION_PATTERN_DURATION_MS)
    }

    private fun playSingleVibrationCycle(intensityIndex: Int) {
        val targetVibrator = vibrator ?: return
        // Scale amplitude based on intensity: gentle=40%, standard=70%, aggressive=100%
        val scale = when (intensityIndex) {
            0 -> 0.4
            1 -> 0.7
            else -> 1.0
        }
        // Amplitudes: even indices = pause (0), odd indices = vibrate (scaled)
        val amplitudes = IntArray(VIBRATION_PATTERN.size) { i ->
            if (i % 2 == 0) 0 else (255 * scale).toInt().coerceIn(1, 255)
        }

        val alarmAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            targetVibrator.cancel()
            targetVibrator.vibrate(
                VibrationEffect.createWaveform(VIBRATION_PATTERN, amplitudes, -1),
                alarmAttributes,
            )
        } else {
            @Suppress("DEPRECATION")
            targetVibrator.cancel()
            targetVibrator.vibrate(VIBRATION_PATTERN, -1)
        }
    }

    private fun stopVibration() {
        loopHandler.removeCallbacks(vibrationLoopRunnable)
        vibrator?.cancel()
        vibrator = null
    }

    private fun scheduleAutoStop() {
        cancelAutoStop()
        val minutes = AlarmPrefs.getSilenceAfterMinutes(this) ?: return
        if (minutes <= 0) return

        autoStopRunnable = Runnable {
            if (!isAlarmActive()) return@Runnable
            Log.i(TAG, "Auto-stopping alarm after $minutes minutes")
            stopAlarmAndSelf()
        }
        loopHandler.postDelayed(autoStopRunnable!!, minutes * 60 * 1000L)
    }

    private fun cancelAutoStop() {
        autoStopRunnable?.let(loopHandler::removeCallbacks)
        autoStopRunnable = null
    }

    private fun stopAlarmAndSelf() {
        activeAlarmId = null
        activeSound = SOUND_SILENT
        activeVibrate = false
        activeVibrationIntensity = 1
        activeGradualVolume = false
        currentVolume = MAX_VOLUME
        cancelAutoStop()
        loopHandler.removeCallbacks(screenOffRecoveryRunnable)
        AlarmPrefs.clearPendingRingingAlarmId(this)
        stopPlayback()
        stopVibration()
        releaseWakeLock()
        cancelAlertNotification()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun cancelAlertNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(alertNotificationId)
    }

    private fun registerScreenStateReceiver() {
        if (isScreenReceiverRegistered) return
        ContextCompat.registerReceiver(
            this,
            screenStateReceiver,
            IntentFilter(Intent.ACTION_SCREEN_OFF),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        isScreenReceiverRegistered = true
    }

    private fun unregisterScreenStateReceiver() {
        if (!isScreenReceiverRegistered) return
        runCatching { unregisterReceiver(screenStateReceiver) }
        isScreenReceiverRegistered = false
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val foregroundChannel = NotificationChannel(
            FOREGROUND_CHANNEL_ID,
            "Alarm Playback",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps the alarm playback service alive"
            lockscreenVisibility = NotificationCompat.VISIBILITY_PRIVATE
            setShowBadge(false)
            setSound(null, null)
            enableVibration(false)
        }
        manager.createNotificationChannel(foregroundChannel)

        val alertChannel = NotificationChannel(
            ALERT_CHANNEL_ID,
            "Alarm Alerts",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Channel for alarm ringing and full-screen alarm UI"
            lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            setShowBadge(false)
            setSound(null, null)
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 250, 150, 250)
        }
        manager.createNotificationChannel(alertChannel)
    }

    private fun resolveAlarmUri(sound: Int): Uri? {
        val primaryType = when (sound) {
            SOUND_GENTLE, SOUND_NATURE -> RingtoneManager.TYPE_NOTIFICATION
            SOUND_CLASSIC -> RingtoneManager.TYPE_RINGTONE
            else -> RingtoneManager.TYPE_ALARM
        }

        return RingtoneManager.getDefaultUri(primaryType)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
    }

    companion object {
        const val ACTION_START = "com.nextalarm.next_alarm.ALARM_RINGING_START"
        const val ACTION_STOP = "com.nextalarm.next_alarm.ALARM_RINGING_STOP"
        private const val FOREGROUND_CHANNEL_ID = "alarm_playback_channel"
        private const val ALERT_CHANNEL_ID = "alarm_alert_channel"
        private const val BASE_NOTIFICATION_ID = 42000
        private const val ALERT_NOTIFICATION_OFFSET = 100000
        private const val SOUND_GENTLE = 1
        private const val SOUND_CLASSIC = 3
        private const val SOUND_NATURE = 4
        private const val SOUND_SILENT = 5 // AlarmSound.silent index in Dart enum
        private const val RINGTONE_MONITOR_INTERVAL_MS = 1000L
        private const val VOLUME_STEP_INTERVAL_MS = 5000L
        private const val SCREEN_OFF_RECOVERY_DELAY_MS = 350L
        private const val WAKE_LOCK_TIMEOUT_MS = 30 * 60 * 1000L
        private const val TAG = "AlarmRingingService"
        private const val INITIAL_VOLUME = 0.1f
        private const val MAX_VOLUME = 1.0f
        private const val VOLUME_STEP = 0.15f
        private val VIBRATION_PATTERN = longArrayOf(
            0, 100, 50, 100, 50, 200, 100, 100,
            200, 500, 100, 300,
            400, 80, 40, 80, 40, 80, 40, 80, 40, 80,
            200, 600, 100, 400,
        )
        private val VIBRATION_PATTERN_DURATION_MS = VIBRATION_PATTERN.sum()
    }
}
