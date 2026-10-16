package com.samaommy.iqra

import android.hardware.GeomagneticField
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Magnetic declination (the angle between magnetic and true north) for a place, from the device's own world magnetic model.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "iqra/geo").setMethodCallHandler { call, result ->
            if (call.method == "declination") {
                val lat = (call.argument<Double>("lat") ?: 0.0).toFloat()
                val lon = (call.argument<Double>("lon") ?: 0.0).toFloat()
                val field = GeomagneticField(lat, lon, 0f, System.currentTimeMillis())
                result.success(field.declination.toDouble())
            } else {
                result.notImplemented()
            }
        }
    }
}
