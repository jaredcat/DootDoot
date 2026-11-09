allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Plugins such as flutter_local_notifications set `compileSdk = 37`, which AGP
// resolves to android-37. The installed SDK platform is android-37.0.
subprojects {
    pluginManager.withPlugin("com.android.library") {
        extensions.configure<com.android.build.api.variant.LibraryAndroidComponentsExtension>(
            "androidComponents",
        ) {
            finalizeDsl { ext ->
                val sdk = ext.compileSdk
                if (sdk != null && sdk >= 37 && ext.compileSdkMinor == null) {
                    ext.compileSdkMinor = 0
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
