package com.samaommy.iqra

import android.content.Intent
import android.hardware.GeomagneticField
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.content.FileProvider
import com.ryanheise.audioservice.AudioServiceActivity
import org.json.JSONArray
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : AudioServiceActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Ask for the screen's fastest refresh rate (90 / 120 Hz phones otherwise often stay at 60), at the same resolution.
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                @Suppress("DEPRECATION")
                val display = windowManager.defaultDisplay
                val current = display.mode
                val best = display.supportedModes
                    .filter { it.physicalWidth == current.physicalWidth && it.physicalHeight == current.physicalHeight }
                    .maxByOrNull { it.refreshRate }
                if (best != null && best.refreshRate > current.refreshRate + 1f) {
                    val lp = window.attributes
                    lp.preferredDisplayModeId = best.modeId
                    window.attributes = lp
                }
            }
        } catch (_: Throwable) {
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The call to prayer: alarms that start the adhan service (see Adhan.kt).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "iqra/adhan").setMethodCallHandler { call, result ->
            when (call.method) {
                "schedule" -> {
                    AdhanScheduler.schedule(this, JSONArray(call.argument<String>("items") ?: "[]"))
                    result.success(true)
                }
                "cancel" -> {
                    AdhanScheduler.cancelAll(this)
                    result.success(true)
                }
                "test" -> {
                    AdhanScheduler.start(this, 9, call.argument<String>("title") ?: "IQRA", call.argument<String>("body") ?: "Prayer reminders are working.", call.argument<Boolean>("adhan") ?: true)
                    result.success(true)
                }
                "setSound" -> {
                    val e = getSharedPreferences("iqra_adhan", MODE_PRIVATE).edit().putInt("sound", call.argument<Int>("n") ?: 1)
                    call.argument<String>("path")?.let { e.putString("path", it) }
                    e.apply()
                    result.success(true)
                }
                "stop" -> {
                    startService(android.content.Intent(this, AdhanService::class.java).setAction("STOP"))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        // Update downloads that carry on while the app is closed (see Downloads.kt).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "iqra/download").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "start" -> result.success(UpdateDownloads.start(this, call.argument<String>("url")!!, call.argument<String>("name")!!))
                    "status" -> result.success(UpdateDownloads.status(this))
                    "cancel" -> {
                        UpdateDownloads.cancel(this)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("download", e.message, null)
            }
        }
        // Sharing a picture straight to WhatsApp, Instagram… and saving it to the gallery (see ShareTargets.kt).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "iqra/share").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "apps" -> result.success(ShareTargets.installed(this))
                    "send" -> result.success(ShareTargets.send(this, call.argument<String>("path")!!, call.argument<String>("pkg"), call.argument<String>("text")))
                    "save" -> result.success(ShareTargets.saveToGallery(this, call.argument<String>("path")!!, call.argument<String>("name")!!))
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("share", e.message, null)
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "iqra/geo").setMethodCallHandler { call, result ->
            when (call.method) {
                // Magnetic declination (the angle between magnetic and true north) for a place, from the device's own world magnetic model.
                "declination" -> {
                    val lat = (call.argument<Double>("lat") ?: 0.0).toFloat()
                    val lon = (call.argument<Double>("lon") ?: 0.0).toFloat()
                    val field = GeomagneticField(lat, lon, 0f, System.currentTimeMillis())
                    result.success(field.declination.toDouble())
                }
                // Whether notifications are allowed for the app (Android 13+ starts with them off), and the system pages to change that.
                "notificationsEnabled" -> result.success(androidx.core.app.NotificationManagerCompat.from(this).areNotificationsEnabled())
                "openNotificationSettings" -> {
                    startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, packageName).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    result.success(true)
                }
                "openBatterySettings" -> {
                    startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    result.success(true)
                }
                // The processor types this phone supports, to pick the right APK when updating.
                "abis" -> result.success(Build.SUPPORTED_ABIS.toList())
                // Hands a downloaded APK to the system installer (asks once for permission to install apps).
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("no_path", "No file given", null)
                    } else if (!packageManager.canRequestPackageInstalls()) {
                        startActivity(
                            Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName")).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success("permission")
                    } else {
                        val uri = FileProvider.getUriForFile(this, "$packageName.updates", File(path))
                        val intent = Intent(Intent.ACTION_VIEW)
                            .setDataAndType(uri, "application/vnd.android.package-archive")
                            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success("started")
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
