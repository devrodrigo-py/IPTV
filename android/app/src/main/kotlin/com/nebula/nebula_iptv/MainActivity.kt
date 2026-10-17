package com.nebula.nebula_iptv

import io.flutter.embedding.android.FlutterActivity
import android.app.UiModeManager
import android.content.Context
import android.content.pm.PackageManager
import android.content.res.Configuration
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nebula/device")
            .setMethodCallHandler { call, result ->
                if (call.method == "isTelevision") {
                    val uiMode = getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
                    result.success(
                        uiMode.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION ||
                        packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK) ||
                        packageManager.hasSystemFeature("amazon.hardware.fire_tv")
                    )
                } else result.notImplemented()
            }
    }
}
