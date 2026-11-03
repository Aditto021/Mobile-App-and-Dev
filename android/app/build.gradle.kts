plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.feriwala.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val releaseKeystore = System.getenv("FERIWALA_KEYSTORE_PATH")
    if (!releaseKeystore.isNullOrBlank()) {
        signingConfigs.create("distribution") {
            storeFile = file(releaseKeystore)
            storePassword = System.getenv("FERIWALA_STORE_PASSWORD")?.takeIf { it.isNotBlank() } ?: "android"
            keyAlias = System.getenv("FERIWALA_KEY_ALIAS")?.takeIf { it.isNotBlank() } ?: "androiddebugkey"
            keyPassword = System.getenv("FERIWALA_KEY_PASSWORD")?.takeIf { it.isNotBlank() } ?: "android"
        }
    }
    buildTypes {
        release {
            // CI receives the same existing key through an encrypted secret.
            signingConfig = signingConfigs.getByName(if (releaseKeystore.isNullOrBlank()) "debug" else "distribution")
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
