package com.feriwala.app

import android.app.Activity
import android.content.pm.PackageManager
import io.flutter.plugin.common.MethodChannel

/**
 * Google Play build: Play delivers updates, so the app never downloads or
 * installs packages itself. Only the version name is answered.
 */
class AppUpdates(private val activity: Activity) {
    fun handle(method: String, result: MethodChannel.Result) {
        when (method) {
            "version" -> result.success(
                try {
                    activity.packageManager.getPackageInfo(activity.packageName, 0).versionName.orEmpty()
                } catch (e: PackageManager.NameNotFoundException) {
                    ""
                }
            )
            else -> result.notImplemented()
        }
    }
}
