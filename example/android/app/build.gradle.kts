plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.dart_torrent_handler_example"
    compileSdk = 35 // Override Flutter's default to match plugin requirements

    // Explicitly set the NDK version to match the plugin's requirement
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11 // Update to Java 11 for compatibility
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11" // Update to Java 11
    }

    defaultConfig {
        applicationId = "com.example.dart_torrent_handler_example"
        minSdk = 21 // Minimum SDK for your plugin (already set)
        targetSdk = 35 // Match compileSdk
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Add any additional dependencies if needed (e.g., for testing)
}