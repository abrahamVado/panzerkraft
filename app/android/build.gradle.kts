import org.gradle.api.file.Directory
import org.gradle.api.tasks.Delete

//1.- Replica la topología de Gradle del proyecto xolotl para alinear repositorios y rutas de build.
allprojects {
    //2.- Expone los repositorios principales para todos los subproyectos Android.
    repositories {
        google()
        mavenCentral()
    }
}

//3.- Redirige la carpeta de compilación al mismo nivel compartido que utiliza xolotl.
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

//4.- Ajusta el directorio de build de cada subproyecto para que cuelgue del contenedor unificado.
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

//5.- Fuerza que el módulo app se evalúe primero como lo requiere la herramienta de Flutter.
subprojects {
    project.evaluationDependsOn(":app")
}

//6.- Mantiene la tarea clean para eliminar por completo los artefactos generados.
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
