import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
require(keystorePropertiesFile.exists()) {
    "Missing android/key.properties. Configure the NearRide release keystore before building."
}

val keystoreProperties = Properties().apply {
    load(FileInputStream(keystorePropertiesFile))
}

fun requiredSigningProperty(name: String): String =
    keystoreProperties.getProperty(name)
        ?: error("Missing '$name' in android/key.properties")

android {
    namespace = "com.ekafy.nearride"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.ekafy.nearride"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = requiredSigningProperty("keyAlias")
            keyPassword = requiredSigningProperty("keyPassword")
            storeFile = rootProject.file(requiredSigningProperty("storeFile"))
            storePassword = requiredSigningProperty("storePassword")
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
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
