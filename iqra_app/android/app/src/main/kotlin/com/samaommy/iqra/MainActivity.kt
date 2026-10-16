package com.samaommy.iqra

import android.content.Intent
import android.hardware.GeomagneticField
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "iqra/geo").setMethodCallHandler { call, result ->
            when (call.method) {
                // Magnetic declination (the angle between magnetic and true north) for a place, from the device's own world magnetic model.
                "declination" -> {
                    val lat = (call.argument<Double>("lat") ?: 0.0).toFloat()
                    val lon = (call.argument<Double>("lon") ?: 0.0).toFloat()
                    val field = GeomagneticField(lat, lon, 0f, System.currentTimeMillis())
                    result.success(field.declination.toDouble())
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
