//1.- Gestiona la carga del SDK de Flutter igual que en la configuración de xolotl.
pluginManagement {
    //2.- Obtiene flutter.sdk desde local.properties para ubicar la herramienta correctamente.
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        properties.getProperty("flutter.sdk")
            ?: error("flutter.sdk not set in local.properties")
    }

    //3.- Incluye el build de flutter_tools para habilitar las tareas personalizadas de Flutter.
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    //4.- Replica los repositorios de plugins utilizados por el proyecto de referencia.
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    //5.- Publica los plugins con las versiones alineadas al proyecto xolotl.
    plugins {
        //5.1.- Loader del plugin de Flutter que registra las tareas base.
        id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
        //5.2.- Plugin de Android con la versión 8.9.1 adoptada por la configuración clonada.
        id("com.android.application") version "8.9.1" apply false
        //5.3.- Plugin de Kotlin Android en la versión 1.9.24 compatible con el AGP 8.9.1.
        id("org.jetbrains.kotlin.android") version "1.9.24" apply false
    }
}

//6.- Registra el loader principal del plugin de Flutter para todos los módulos.
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
}

//7.- Expone el módulo de la aplicación dentro del árbol de Gradle.
include(":app")
