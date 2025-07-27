allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Suppress deprecation and unchecked warnings for all projects
    tasks.withType<JavaCompile> {
        options.compilerArgs.addAll(listOf("-Xlint:none"))
        options.compilerArgs.addAll(listOf("-Xlint:-deprecation"))
        options.compilerArgs.addAll(listOf("-Xlint:-unchecked"))
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
