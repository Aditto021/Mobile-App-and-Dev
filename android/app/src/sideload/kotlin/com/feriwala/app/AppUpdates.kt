package com.feriwala.app

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.io.ByteArrayOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.util.concurrent.Executors

/** Public release metadata; no account credentials are shipped in the app. */
class AppUpdates(private val activity: Activity) {
    companion object {
        private const val RELEASES = "https://github.com/Aditto021/Mobile-App-and-Dev/releases/"
        private const val FEED = "${RELEASES}latest/download/feriwala-update.json"
        private const val MAX_APK_BYTES = 150L * 1024 * 1024
        private val executor = Executors.newSingleThreadExecutor()
    }

    private var verifiedApk: File? = null

    @Suppress("DEPRECATION")
    private fun installed(): PackageInfo = activity.packageManager.getPackageInfo(
        activity.packageName, signingFlags())

    private fun signingFlags(): Int = if (Build.VERSION.SDK_INT >= 28)
        PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES

    @Suppress("DEPRECATION")
    private fun version(info: PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()

    private fun connection(address: String): HttpURLConnection {
        var url = URL(address)
        repeat(6) {
            require(url.protocol == "https") { "Updates require HTTPS" }
            val connection = url.openConnection() as HttpURLConnection
            connection.connectTimeout = 15000
            connection.readTimeout = 30000
            connection.instanceFollowRedirects = false
            connection.useCaches = false
            connection.setRequestProperty("User-Agent", "FeriWala-Android")
            val status = connection.responseCode
            if (status in listOf(301, 302, 303, 307, 308)) {
                val next = connection.getHeaderField("Location")
                connection.disconnect()
                require(!next.isNullOrBlank()) { "Invalid update redirect" }
                url = URL(url, next)
            } else return connection
        }
        error("Too many update redirects")
    }

    private fun metadata(): JSONObject? {
        val connection = connection(FEED)
        try {
            if (connection.responseCode == 404) return null
            check(connection.responseCode == 200) { "Update server unavailable" }
            val bytes = connection.inputStream.use { input ->
                val output = ByteArrayOutputStream()
                val buffer = ByteArray(4096)
                while (true) {
                    val count = input.read(buffer)
                    if (count < 0) break
                    require(output.size() + count <= 32768) { "Invalid update metadata" }
                    output.write(buffer, 0, count)
                }
                output.toByteArray()
            }
            val data = JSONObject(bytes.toString(Charsets.UTF_8))
            require(data.getString("packageId") == activity.packageName)
            require(data.getLong("versionCode") > 0)
            require(data.getString("versionName").length in 1..64)
            require(data.getString("sha256").matches(Regex("[a-fA-F0-9]{64}")))
            require(data.getLong("sizeBytes") in 1..MAX_APK_BYTES)
            require(data.getString("apkUrl").startsWith("${RELEASES}download/"))
            return data
        } finally { connection.disconnect() }
    }

    @Suppress("DEPRECATION")
    private fun certificates(info: PackageInfo): Set<String> {
        val signatures = if (Build.VERSION.SDK_INT >= 28)
            info.signingInfo?.apkContentsSigners else info.signatures
        return signatures.orEmpty().map {
            MessageDigest.getInstance("SHA-256").digest(it.toByteArray())
                .joinToString("") { byte -> "%02x".format(byte.toInt() and 255) }
        }.toSet()
    }

    private fun verify(file: File, expectedVersion: Long) {
        val archive = activity.packageManager.getPackageArchiveInfo(file.path, signingFlags())
            ?: error("Downloaded file is not a valid APK")
        val current = installed()
        require(archive.packageName == activity.packageName) { "Wrong application package" }
        require(version(archive) == expectedVersion && version(archive) > version(current)) {
            "Update version does not match"
        }
        val currentCertificates = certificates(current)
        require(currentCertificates.isNotEmpty() && certificates(archive) == currentCertificates) {
            "Update signing certificate does not match this app"
        }
        require((archive.applicationInfo?.minSdkVersion ?: Int.MAX_VALUE) <= Build.VERSION.SDK_INT) {
            "This update requires a newer Android version"
        }
    }

    fun handle(method: String, result: MethodChannel.Result) {
        if (method == "install") {
            try {
                val file = verifiedApk ?: error("Download the update first")
                if (Build.VERSION.SDK_INT >= 26 && !activity.packageManager.canRequestPackageInstalls()) {
                    result.success(false)
                    return
                }
                val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.updates", file)
                activity.startActivity(Intent(Intent.ACTION_VIEW)
                    .setDataAndType(uri, "application/vnd.android.package-archive")
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
                result.success(true)
            } catch (error: Exception) { result.error("install", error.message, null) }
            return
        }
        if (method == "allowInstalls") {
            try {
                if (Build.VERSION.SDK_INT >= 26) activity.startActivity(Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:${activity.packageName}")))
                result.success(null)
            } catch (error: Exception) { result.error("permission", error.message, null) }
            return
        }
        if (method !in listOf("check", "download", "version")) {
            result.notImplemented()
            return
        }
        executor.execute {
            try {
                val current = installed()
                val response: Any = when (method) {
                    "version" -> current.versionName.orEmpty()
                    "check" -> {
                        val data = metadata()
                        mapOf("feedReady" to (data != null),
                            "available" to (data != null && data.getLong("versionCode") > version(current)),
                            "versionName" to data?.optString("versionName"),
                            "notes" to data?.optString("releaseNotes")?.take(4000))
                    }
                    else -> {
                        val data = metadata() ?: error("No release has been published yet")
                        require(data.getLong("versionCode") > version(current)) { "Already up to date" }
                        verifiedApk = null
                        val folder = File(activity.cacheDir, "updates").apply { mkdirs() }
                        val partial = File(folder, "update.part")
                        val connection = connection(data.getString("apkUrl"))
                        try {
                            check(connection.responseCode == 200) { "APK download failed" }
                            val digest = MessageDigest.getInstance("SHA-256")
                            var total = 0L
                            connection.inputStream.use { input ->
                                partial.outputStream().use { output ->
                                    val buffer = ByteArray(65536)
                                    while (true) {
                                        val count = input.read(buffer)
                                        if (count < 0) break
                                        total += count
                                        require(total <= data.getLong("sizeBytes")) { "APK size mismatch" }
                                        digest.update(buffer, 0, count)
                                        output.write(buffer, 0, count)
                                    }
                                }
                            }
                            val hash = digest.digest().joinToString("") { "%02x".format(it.toInt() and 255) }
                            require(total == data.getLong("sizeBytes") &&
                                hash.equals(data.getString("sha256"), ignoreCase = true)) { "APK checksum mismatch" }
                            // PackageManager expects an .apk extension when parsing the archive.
                            val apk = File(folder, "feriwala.apk")
                            partial.copyTo(apk, overwrite = true)
                            verify(apk, data.getLong("versionCode"))
                            verifiedApk = apk
                        } finally {
                            connection.disconnect()
                            partial.delete()
                        }
                        true
                    }
                }
                activity.runOnUiThread { result.success(response) }
            } catch (error: Exception) {
                activity.runOnUiThread { result.error("update", error.message ?: "Update failed", null) }
            }
        }
    }
}
