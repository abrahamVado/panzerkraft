import java.io.File
import java.util.Properties

plugins {
    //1.- Activa el plugin de aplicación Android siguiendo la plantilla de xolotl.
    id("com.android.application")
    //2.- Habilita el plugin de Kotlin Android para compartir la misma pila que la app de referencia.
    id("org.jetbrains.kotlin.android")
    //3.- Aplica el plugin de Flutter después de Android y Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

//4.- Resuelve la API key de Google Maps a partir de variables locales o de entorno.
val mapsApiKey: String by lazy {
    val localProperties = Properties()
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use(localProperties::load)
    }

    val fromEnv = System.getenv("MAPS_API_KEY")?.trim().orEmpty()
    val fromFile = localProperties.getProperty("MAPS_API_KEY")?.trim().orEmpty()

    listOf(fromEnv, fromFile).firstOrNull { it.isNotBlank() } ?: "YOUR_ANDROID_KEY"
}

android {
    //5.- Conserva el namespace original de Panzerkraft alineado con el AndroidManifest.
    namespace = "com.example.app"
    //6.- Sincroniza compileSdk y ndk con los valores resueltos por Flutter.
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    //7.- Alinea la compatibilidad de Java con la configuración importada y los requisitos del AGP 7.4.
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    //8.- Configura Kotlin para emitir bytecode compatible con Java 17.
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        //9.- Mantiene el applicationId anterior respetando la estructura existente.
        applicationId = "com.example.app"
        //10.- Reutiliza el versionado administrado por Flutter.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        //11.- Expone la API key al AndroidManifest mediante placeholders.
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    //12.- Define sabores citizen/admin replicando la referencia y usando citizen como predeterminado.
    flavorDimensions.add("app")
    productFlavors {
        create("citizen") {
            dimension = "app"
            isDefault = true
            applicationIdSuffix = ".citizen"
            versionNameSuffix = "-citizen"
        }
        create("admin") {
            dimension = "app"
            applicationIdSuffix = ".admin"
            versionNameSuffix = "-admin"
        }
    }

    //13.- Mantiene la firma de release con las claves de depuración para builds locales.
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

//14.- Informa al plugin de Flutter dónde se ubica el código Dart.
flutter {
    source = "../.."
}

dependencies {
    //15.- Agrega Material Components para estilos coherentes con la referencia.
    implementation("com.google.android.material:material:1.12.0")
}

//16.- Declara el sabor predeterminado que Flutter debe usar al generar artefactos.
val defaultFlutterFlavor = "citizen"

//17.- Copia el APK generado por Gradle al directorio monitoreado por Flutter.
fun registerFlutterApkCopyTask(buildType: String) {
    tasks.matching { it.name == "assemble${buildType.replaceFirstChar { ch -> ch.uppercase() }}" }
        .configureEach {
            doLast {
                val variantApk = File(
                    buildDir,
                    "outputs/apk/$defaultFlutterFlavor/${buildType.lowercase()}/app-$defaultFlutterFlavor-${buildType.lowercase()}.apk",
                )

                val flutterOutputDir = File(buildDir, "outputs/flutter-apk")

                if (variantApk.exists()) {
                    flutterOutputDir.mkdirs()
                    variantApk.copyTo(File(flutterOutputDir, "app-${buildType.lowercase()}.apk"), overwrite = true)
                } else {
                    logger.warn("No se encontró el APK ${variantApk.path} tras ejecutar ${name}.")
                }
            }
        }
}

//18.- Registra la sincronización para los tipos de compilación soportados por Flutter.
listOf("debug", "profile", "release").forEach(::registerFlutterApkCopyTask)
