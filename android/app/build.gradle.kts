plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.poc_liquidekyc_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.poc_liquidekyc_flutter"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    packaging {
        jniLibs {
            excludes += listOf(
                "**/libVkLayer_khronos_validation.so",
                "**/libVkLayer_khronos_interceptor.so"
            )
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
        }
    }

    bundle {
        language {
            enableSplit = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(fileTree("libs") { include("*.aar", "*.jar") })
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.9.0")
    implementation("org.jetbrains.kotlin:kotlin-stdlib")
    implementation("androidx.activity:activity-ktx:1.9.3")

    implementation("com.google.ai.edge.litert:litert:1.4.0")
    implementation("com.google.mlkit:text-recognition-japanese:16.0.1")
    
    // Chucker for HTTP traffic logging (SDK native calls)
    debugImplementation("com.github.chuckerteam.chucker:library:4.0.0")
    releaseImplementation("com.github.chuckerteam.chucker:library-no-op:4.0.0")
}