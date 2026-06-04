allprojects {
    repositories {
        // 本地 libs 目录优先查找（放置手工下载的 jar）
        flatDir {
            dirs("$rootDir/libs")
        }

        // 优先使用 mavenCentral 和 google，确保能找到最新依赖
        google()
        mavenCentral()
        
        // 阿里云镜像作为备用
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        
        // Flutter Android 依赖仓库（使用中国镜像）
        maven { url = uri("https://storage.flutter-io.cn/download.flutter.io") }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
