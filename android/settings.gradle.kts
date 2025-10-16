//1.- Carga la ruta del SDK de Flutter desde local.properties.
pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use(properties::load)
        properties.getProperty("flutter.sdk") ?: error("flutter.sdk not set in local.properties")
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

//2.- Declara los plugins principales que usará el proyecto Android.
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

//3.- Registra el módulo de la aplicación.
include(":app")
