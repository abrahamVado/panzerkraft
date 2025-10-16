plugins {
    //1.- Plugin de aplicación Android requerido para generar el APK.
    id("com.android.application")
    //2.- Habilita Kotlin para la actividad principal.
    id("org.jetbrains.kotlin.android")
    //3.- Integra las tareas de Flutter en el módulo Android.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    //4.- Namespace alineado con el paquete configurado en el Manifest.
    namespace = "com.panzerkraft.demo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        //5.- Ajusta la compatibilidad de Java a la versión recomendada por Flutter 3.22.
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        //6.- Emite bytecode compatible con JVM 17.
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        //7.- Identificador único del paquete Android generado.
        applicationId = "com.panzerkraft.demo"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            //8.- Mantiene la firma de depuración para simplificar la distribución de la demo.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    //9.- Indica al plugin dónde encontrar el código Dart de la app.
    source = "../.."
}

dependencies {
    //10.- Material Components garantiza consistencia con los widgets de Flutter en Android.
    implementation("com.google.android.material:material:1.12.0")
}
