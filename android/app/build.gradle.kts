plugins {
    id("com.android.application")
    id("com.google.gms.google-services") 
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}


android {
    //compileSdk = flutter.compileSdkVersion
    compileSdk = 35
    //ndkVersion = flutter.ndkVersion
    ndkVersion = "27.0.12077973"
    namespace = "com.example.flutter_application_2"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.giakhanh.piranha"
        //minSdk = flutter.minSdkVersion
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = file("${System.getProperty("user.home")}/.android/key-release-piranha.keystore")
            storePassword = "giakhanh123"
            keyAlias = "key-release"
            keyPassword = "giakhanh123"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            //signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}



dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.2")) // bản 33 chạy kotlin 2.0.10  - bản 32 chạy 1.9.X
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.android.gms:play-services-auth:20.8.0")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:${rootProject.extra.get("kotlin_version")}")
}
