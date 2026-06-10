// Top-level: Load signing properties
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystoreFile = rootProject.file("key.properties")
if (keystoreFile.exists()) {
    keystoreProperties.load(FileInputStream(keystoreFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.github.triplet.play")
}

android {
    namespace = "com.angriff.x_video_downloader"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.angriff.x_video_downloader"
        // minSdkVersion flutter.minSdkVersion  <-- invalid Groovy syntax auto-inserted; keep commented
        minSdkVersion(flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appAuthRedirectScheme"] = "com.angriff.x_video_downloader"
    }

    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }

    buildTypes {
        getByName("debug") {
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
        }
        getByName("release") {
            // Enable R8 (code shrinking & obfuscation) to generate mapping.txt
            isMinifyEnabled = true
			isShrinkResources = true
            // Supply optimized default ProGuard and custom rules
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            ndk {
                // Generate native debug symbols (FULL or SYMBOL_TABLE). Upload to Play to improve crash reports.
                debugSymbolLevel = "FULL"
            }
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

// Gradle Play Publisher configuration.
// Requires a Google Play service-account JSON key at android/play-service-account.json
// (git-ignored). See Play Console -> Setup -> API access to create one.
// Publish with, e.g.:  ./gradlew publishReleaseBundle      (uploads the signed AAB)
play {
    val credsFile = rootProject.file("play-service-account.json")
    if (credsFile.exists()) {
        serviceAccountCredentials.set(credsFile)
    }
    // Default to the lowest-risk track; override on the CLI with --track production, etc.
    track.set("internal")
    defaultToAppBundles.set(true)
    // Roll out fully once accepted on the chosen track.
    releaseStatus.set(com.github.triplet.gradle.androidpublisher.ReleaseStatus.COMPLETED)
}

dependencies {
    implementation(kotlin("stdlib-jdk8"))
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
