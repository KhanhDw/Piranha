plugins {
    id("com.android.application") version "8.7.0" apply false 
    id("com.google.gms.google-services") version "4.4.2" apply false 
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
   dependencies {
        classpath("com.android.tools.build:gradle:8.7.0") // Đảm bảo phiên bản này đúng
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22") // CẬP NHẬT phiên bản Kotlin plugin lên 1.9.22 hoặc mới hơn
        classpath("com.google.gms:google-services:4.4.2") // Đảm bảo phiên bản này đúng
        classpath("io.flutter.tools.gradle:flutter-gradle-plugin")
    }
    extra.apply {
        set("kotlin_version", "1.9.22") // CẬP NHẬT phiên bản Kotlin
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


