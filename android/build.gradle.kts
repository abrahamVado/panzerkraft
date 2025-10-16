//1.- Configura los repositorios compartidos para todos los módulos.
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

//2.- Define la tarea clean estándar proporcionada por Gradle.
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
