package com.feriwala.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val updates = AppUpdates(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "feriwala/updates")
            .setMethodCallHandler { call, result -> updates.handle(call.method, result) }
    }
}
