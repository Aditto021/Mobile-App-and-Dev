import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Two ways to ship the same app:
//  - Google Play (default): signed with the upload key from
//    android/key.properties; Play delivers updates.
//  - Direct download from GitHub Releases (-P sideload=true): keeps the
//    original certificate and the in-app updater.
val sideload = providers.gradleProperty("sideload").orNull == "true"

val uploadKey = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "com.feriwala.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.feriwala.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Both come from `version:` in pubspec.yaml (name+code).
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    sourceSets {
        getByName("main") {
            java.srcDir(if (sideload) "src/sideload/kotlin" else "src/store/kotlin")
            if (sideload) res.srcDir("src/sideload/res")
        }
        if (sideload) {
            getByName("release") { manifest.srcFile("src/sideload/AndroidManifest.xml") }
        }
    }

    val sideloadKeystore = System.getenv("FERIWALA_KEYSTORE_PATH")
    if (sideload && !sideloadKeystore.isNullOrBlank()) {
        signingConfigs.create("distribution") {
            storeFile = file(sideloadKeystore)
            storePassword = System.getenv("FERIWALA_STORE_PASSWORD")?.takeIf { it.isNotBlank() } ?: "android"
            keyAlias = System.getenv("FERIWALA_KEY_ALIAS")?.takeIf { it.isNotBlank() } ?: "androiddebugkey"
            keyPassword = System.getenv("FERIWALA_KEY_PASSWORD")?.takeIf { it.isNotBlank() } ?: "android"
        }
    }
    val hasUploadKey = uploadKey.getProperty("storeFile") != null
    if (!sideload && hasUploadKey) {
        signingConfigs.create("upload") {
            storeFile = file(uploadKey.getProperty("storeFile"))
            storePassword = uploadKey.getProperty("storePassword")
            keyAlias = uploadKey.getProperty("keyAlias")
            keyPassword = uploadKey.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                when {
                    sideload && !sideloadKeystore.isNullOrBlank() -> "distribution"
                    !sideload && hasUploadKey -> "upload"
                    else -> "debug"
                }
            )
            if (!sideload && !hasUploadKey) {
                logger.warn("WARNING: android/key.properties is missing — this release is debug-signed and Google Play will refuse it.")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
