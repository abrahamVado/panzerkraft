import java.io.File
import java.util.Properties
import org.gradle.api.GradleException

plugins {
    //1.- Activa el plugin de aplicación Android siguiendo la configuración del proyecto de referencia.
    id("com.android.application")
    //2.- Habilita compatibilidad con Kotlin para compartir la misma pila que la app ciudadana.
    id("kotlin-android")
    //3.- Aplica el plugin de Flutter después de los plugins de Android y Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

//1.- mapsApiKey resuelve el API key de Google Maps desde variables locales o de entorno.
val mapsApiKey: String by lazy {
    //1.1.- Cargamos local.properties para admitir configuraciones en equipos de desarrollo.
    val localProperties = Properties()
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use(localProperties::load)
    }

    //1.2.- Normalizamos los valores obtenidos tanto del archivo como del entorno.
    val fromEnv = System.getenv("MAPS_API_KEY")?.trim().orEmpty()
    val fromFile = localProperties.getProperty("MAPS_API_KEY")?.trim().orEmpty()

    //1.3.- Priorizamos la variable de entorno seguida del archivo y usamos el placeholder por defecto.
    listOf(fromEnv, fromFile).firstOrNull { it.isNotBlank() } ?: "YOUR_ANDROID_KEY"
}

android {
    //1.- Mantiene el namespace original de la aplicación alineado con el AndroidManifest renombrado.
    namespace = "com.example.ubberapp"
    //2.- Sincroniza compileSdk y ndk con los valores resueltos por Flutter.
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    //3.- Ajusta la compatibilidad de Java igual que en el proyecto de referencia.
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    //4.- Configura Kotlin para emitir bytecode objetivo Java 11.
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        //5.- Conserva el nuevo applicationId renombrado para evitar colisiones con la app previa.
        applicationId = "com.example.ubberapp"
        //6.- Replica la obtención dinámica de versionado administrado por Flutter.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        //6.1.- Exponemos el API key para que el AndroidManifest lo reciba vía placeholders.
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    //7.- Porta la misma configuración de sabores citizen/admin proveniente de la app de referencia.
    flavorDimensions.add("app")
    productFlavors {
        //7.1.- Flutter toma este sabor como predeterminado al declararlo en primer lugar.
create("citizen") {
        dimension = "app"
        applicationIdSuffix = ".citizen"
        versionNameSuffix = "-citizen"
    }
create("admin") {
        dimension = "app"
        applicationIdSuffix = ".admin"
        versionNameSuffix = "-admin"
    }
    }

    //8.- Mantiene la firma de release utilizando las claves de depuración como en la referencia.
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

//9.- Señala al plugin de Flutter el directorio raíz del código fuente Dart.
flutter {
    source = "../.."
}

dependencies {
    //10.- Agrega Material Components para proporcionar el tema usado por los estilos Android.
    implementation("com.google.android.material:material:1.12.0")
}

//11.- Define el sabor predeterminado que Flutter debe usar para generar los artefactos esperados.
val defaultFlutterFlavor = "citizen"

//12.- Función auxiliar que copia el APK generado al directorio monitoreado por Flutter.
fun registerFlutterApkCopyTask(buildType: String) {
    //12.1.- Localiza la tarea assemble correspondiente al tipo de compilación indicado.
    tasks.matching { it.name == "assemble${buildType.replaceFirstChar { ch -> ch.uppercase() }}" }
        .configureEach {
            //12.2.- Agrega un paso final que copia y renombra el APK del sabor predeterminado.
            doLast {
                //12.2.1.- Ruta del APK generado por Gradle para el sabor predeterminado.
                val variantApk = File(
                    buildDir,
                    "outputs/apk/$defaultFlutterFlavor/${buildType.lowercase()}/app-$defaultFlutterFlavor-${buildType.lowercase()}.apk",
                )

                //12.2.2.- Directorio esperado por la herramienta de Flutter para instalar el APK.
                val flutterOutputDir = File(buildDir, "outputs/flutter-apk")

                //12.2.3.- Copia el archivo cuando está disponible y avisa si falta para facilitar el diagnóstico.
                if (variantApk.exists()) {
                    flutterOutputDir.mkdirs()
                    variantApk.copyTo(File(flutterOutputDir, "app-${buildType.lowercase()}.apk"), overwrite = true)
                } else {
                    logger.warn("No se encontró el APK ${variantApk.path} tras ejecutar ${name}.")
                }
            }
        }
}

//13.- Registra la sincronización para los tipos de compilación soportados por Flutter.
listOf("debug", "profile", "release").forEach(::registerFlutterApkCopyTask)

//14.- launcherIconSource ubica el PNG suministrado manualmente dentro del árbol de assets.
val launcherIconSource: File = rootProject.file("assets/icon/app_icon.png")

//15.- launcherIconDensities define los directorios de mipmap que deben recibir el PNG.
val launcherIconDensities = listOf("mipmap-mdpi", "mipmap-hdpi", "mipmap-xhdpi", "mipmap-xxhdpi", "mipmap-xxxhdpi")

//16.- syncLauncherIcon replica el ícono en los recursos esperados antes de compilar.
val syncLauncherIcon = tasks.register("syncLauncherIcon") {
    //16.1.- Declaramos el archivo de entrada para habilitar la incrementalidad del task.
    inputs.file(launcherIconSource)

    //16.2.- Enumeramos los destinos para que Gradle detecte cambios en los recursos.
    val outputsList = launcherIconDensities.map { density ->
        File(projectDir, "src/main/res/$density/app_icon.png")
    }
    outputs.files(outputsList)

    //16.3.- Copiamos el PNG o detenemos la compilación si el recurso no fue proporcionado.
    doLast {
        if (!launcherIconSource.exists()) {
            throw GradleException("Falta assets/icon/app_icon.png; agrega el PNG antes de compilar.")
        }
        outputsList.forEach { target ->
            target.parentFile.mkdirs()
            launcherIconSource.copyTo(target, overwrite = true)
        }
    }
}

//17.- Hacemos que la etapa de preBuild exija la sincronización del ícono.
tasks.named("preBuild").configure { dependsOn(syncLauncherIcon) }
