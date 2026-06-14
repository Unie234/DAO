plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.dao_culture_app"
    
    // 🔴 QUAN TRỌNG: Sửa thành 36 để chạy được các Plugin mới nhất
    compileSdk = 36 

    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // ID này phải khớp với ID trên Firebase của Uyên nha
        applicationId = "com.example.dao_culture_app"
        
        // minSdk 23 là đủ để chạy trên hầu hết các máy Android hiện nay
        minSdk = 24
        
        // 🔴 QUAN TRỌNG: Sửa thành 36 để đồng bộ với compileSdk
        targetSdk = 36 

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Nếu có thêm thư viện native nào thì viết ở đây, thường là để trống
}