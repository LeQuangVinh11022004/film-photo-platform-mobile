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

// Trên CI (GitHub Actions), ép TẤT CẢ subprojects (cả :app lẫn mọi Flutter plugin)
// dùng đúng phiên bản NDK đã cài sẵn trên runner để Gradle KHÔNG tải lại NDK 28.2 (~2GB) mỗi lần build.
val ciNdkVersion = System.getenv("ANDROID_NDK_VERSION")?.takeIf { it.isNotBlank() }
if (ciNdkVersion != null) {
    subprojects {
        afterEvaluate {
            val androidExt = extensions.findByName("android")
            if (androidExt != null) {
                try {
                    androidExt.javaClass.getMethod("setNdkVersion", String::class.java)
                        .invoke(androidExt, ciNdkVersion)
                } catch (_: Exception) {
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
