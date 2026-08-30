package com.carrierlock.app

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val MAPS_CHANNEL = "com.carrierlock.app/maps"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MAPS_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openMaps") {
                val lat = call.argument<Double>("lat") ?: 0.0
                val lng = call.argument<Double>("lng") ?: 0.0
                val uri = Uri.parse("geo:$lat,$lng?q=$lat,$lng")
                val intent = Intent(Intent.ACTION_VIEW, uri)
                intent.setPackage("com.google.android.apps.maps")
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    result.success(null)
                } else {
                    // Fall back to browser maps
                    val browserUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng")
                    val browserIntent = Intent(Intent.ACTION_VIEW, browserUri)
                    startActivity(browserIntent)
                    result.success(null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
