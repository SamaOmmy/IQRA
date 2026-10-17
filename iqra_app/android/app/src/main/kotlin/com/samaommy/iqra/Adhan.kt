package com.samaommy.iqra

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject

/**
 * The call to prayer. Each prayer time is an alarm-clock alarm (exact, and allowed to wake the phone in Doze), which starts a
 * foreground service that plays the adhan on the alarm audio stream, so it sounds like an alarm even when the app is closed.
 * The schedule is kept on the device and re-armed after a restart.
 */
object AdhanScheduler {
    private const val PREFS = "iqra_adhan"
    private const val KEY = "schedule"

    fun schedule(ctx: Context, items: JSONArray) {
        cancelAll(ctx)
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, items.toString()).apply()
        arm(ctx, items)
    }

    /** Arms every entry that is still in the future. */
    fun arm(ctx: Context, items: JSONArray) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val now = System.currentTimeMillis()
        for (i in 0 until items.length()) {
            val o = items.getJSONObject(i)
            val at = o.getLong("at")
            if (at <= now) continue
            val show = PendingIntent.getActivity(
                ctx, 0, Intent(ctx, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            am.setAlarmClock(AlarmManager.AlarmClockInfo(at, show), pending(ctx, o))
        }
    }

    fun cancelAll(ctx: Context) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val saved = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null) ?: return
        try {
            val items = JSONArray(saved)
            for (i in 0 until items.length()) am.cancel(pending(ctx, items.getJSONObject(i)))
        } catch (_: Exception) {
        }
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().remove(KEY).apply()
    }

    fun rearmSaved(ctx: Context) {
        val saved = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null) ?: return
        try {
            arm(ctx, JSONArray(saved))
        } catch (_: Exception) {
        }
    }

    private fun pending(ctx: Context, o: JSONObject): PendingIntent {
        val intent = Intent(ctx, AdhanReceiver::class.java)
            .putExtra("id", o.getInt("id"))
            .putExtra("title", o.optString("title"))
            .putExtra("body", o.optString("body"))
            .putExtra("adhan", o.optBoolean("adhan", true))
        return PendingIntent.getBroadcast(ctx, o.getInt("id"), intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    }

    fun start(ctx: Context, id: Int, title: String, body: String, adhan: Boolean) {
        val i = Intent(ctx, AdhanService::class.java)
            .putExtra("id", id).putExtra("title", title).putExtra("body", body).putExtra("adhan", adhan)
        ContextCompat.startForegroundService(ctx, i)
    }
}

class AdhanReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        AdhanScheduler.start(
            context, intent.getIntExtra("id", 1), intent.getStringExtra("title") ?: "Prayer time",
            intent.getStringExtra("body") ?: "", intent.getBooleanExtra("adhan", true)
        )
    }
}

class AdhanBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        AdhanScheduler.rearmSaved(context)
    }
}

class AdhanService : Service() {
    private var player: MediaPlayer? = null
    private var wake: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP") {
            finish(null)
            return START_NOT_STICKY
        }
        val id = intent?.getIntExtra("id", 1) ?: 1
        val title = intent?.getStringExtra("title") ?: "Prayer time"
        val body = intent?.getStringExtra("body") ?: ""
        val adhan = intent?.getBooleanExtra("adhan", true) ?: true
        channels()

        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val stop = PendingIntent.getService(this, 1, Intent(this, AdhanService::class.java).setAction("STOP"), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val live = NotificationCompat.Builder(this, "adhan_live")
            .setSmallIcon(R.drawable.ic_stat_adhan).setContentTitle(title).setContentText(body)
            .setCategory(NotificationCompat.CATEGORY_ALARM).setPriority(NotificationCompat.PRIORITY_MAX)
            .setContentIntent(open).setOngoing(true).setOnlyAlertOnce(true)
            .addAction(0, "Stop", stop).build()
        if (Build.VERSION.SDK_INT >= 29) startForeground(7001, live, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK) else startForeground(7001, live)

        // the notice that stays in the tray afterwards
        val keep = NotificationCompat.Builder(this, "adhan_note")
            .setSmallIcon(R.drawable.ic_stat_adhan).setContentTitle(title).setContentText(body)
            .setContentIntent(open).setAutoCancel(true).build()
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).notify(7100 + id, keep)

        if (!adhan) {
            finish(null)
            return START_NOT_STICKY
        }
        try {
            wake = (getSystemService(POWER_SERVICE) as PowerManager).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "iqra:adhan").apply { acquire(6 * 60 * 1000L) }
            // the recording chosen in Settings (1 is the first one, the others are adhan_2, adhan_3)
            val n = getSharedPreferences("iqra_adhan", Context.MODE_PRIVATE).getInt("sound", 2)
            var res = resources.getIdentifier(if (n <= 1) "adhan" else "adhan_$n", "raw", packageName)
            if (res == 0) res = R.raw.adhan
            val afd = resources.openRawResourceFd(res)
            player?.release()
            player = MediaPlayer().apply {
                setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build())
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()
                setOnCompletionListener { finish(null) }
                setOnErrorListener { _, _, _ -> finish(null); true }
                prepare()
                start()
            }
        } catch (_: Exception) {
            finish(null)
        }
        return START_NOT_STICKY
    }

    private fun finish(@Suppress("UNUSED_PARAMETER") x: Any?) {
        try {
            player?.stop()
        } catch (_: Exception) {
        }
        player?.release()
        player = null
        try {
            if (wake?.isHeld == true) wake?.release()
        } catch (_: Exception) {
        }
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        player?.release()
        player = null
        super.onDestroy()
    }

    private fun channels() {
        if (Build.VERSION.SDK_INT < 26) return
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        nm.createNotificationChannel(NotificationChannel("adhan_live", "Adhan playing", NotificationManager.IMPORTANCE_HIGH).apply { setSound(null, null); description = "Shown while the call to prayer plays" })
        nm.createNotificationChannel(NotificationChannel("adhan_note", "Prayer times", NotificationManager.IMPORTANCE_DEFAULT).apply { description = "A note when a prayer time begins" })
    }
}
