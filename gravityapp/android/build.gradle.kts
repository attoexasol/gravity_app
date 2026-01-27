import org.gradle.api.JavaVersion
import org.gradle.api.plugins.JavaPluginExtension
import org.gradle.jvm.toolchain.JavaLanguageVersion
import com.android.build.gradle.LibraryExtension
import com.android.build.gradle.AppExtension
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2") // ✅ REQUIRED
    }
}

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

// CRITICAL: Register afterEvaluate FIRST, before evaluationDependsOn causes evaluation
// This ensures we can configure Flutter plugins like :health that are applied dynamically
subprojects {
    // Register afterEvaluate early to catch all plugins including Flutter-managed ones
    project.afterEvaluate {
        // Configure Android library projects (including Flutter plugins like :health)
        if (project.plugins.hasPlugin("com.android.library")) {
            try {
                val android = project.extensions.findByName("android")
                if (android != null && android is LibraryExtension) {
                    android.compileOptions {
                        sourceCompatibility = JavaVersion.VERSION_17
                        targetCompatibility = JavaVersion.VERSION_17
                    }
                }
            } catch (e: Exception) {
                // compileOptions might be finalized, try alternative approach
                // This is expected for some plugins and we'll handle it via allprojects
            }
        }
        
        // Configure ALL Kotlin tasks to use JVM 17 (this can be done after evaluation)
        project.tasks.withType<KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = "17"
            }
        }
    }
}

// This must come AFTER afterEvaluate registration
subprojects {
    project.evaluationDependsOn(":app")
}

// Configure Java 17 for all subprojects (plugins) to eliminate Java 8 warnings
// Using allprojects with plugins.withId to configure DURING plugin application (before finalization)
allprojects {
    // Configure Java projects
    plugins.withId("java") {
        extensions.configure<JavaPluginExtension>("java") {
            toolchain {
                languageVersion.set(JavaLanguageVersion.of(17))
            }
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }
    }
    
    plugins.withId("java-library") {
        extensions.configure<JavaPluginExtension>("java") {
            toolchain {
                languageVersion.set(JavaLanguageVersion.of(17))
            }
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }
    }
    
    // Configure Android library projects - configure compileOptions BEFORE finalization
    // This is the primary way to set Java 17 for plugins like :health
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension>("android") {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
    
    // Configure Android application projects (excluding :app which is already configured)
    plugins.withId("com.android.application") {
        if (project.name != "app") {
            extensions.configure<AppExtension>("android") {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
    }
    
    // Configure Kotlin JVM target for all Kotlin projects
    plugins.withId("org.jetbrains.kotlin.jvm") {
        tasks.withType<KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = "17"
            }
        }
    }
    
    plugins.withId("org.jetbrains.kotlin.android") {
        tasks.withType<KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = "17"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
