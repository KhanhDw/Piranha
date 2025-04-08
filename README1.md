# flutter_application_2

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


lệnh build app apk
flutter clean
flutter pub get 
--> hoặc thêm mới:  flutter pub add <package_name>

flutter build apk --release

flutter run


Chạy lệnh tạo icon
flutter pub run flutter_launcher_icons


Ctrl + P : tìm file bằng copy đường dẫn
điều chỉnh lại AplicationID tại: android\app\src\main\AndroidManifest.xml
điều chỉnh lại id quảng cáo thât: "adUnitId:" -->  lib\main.dart




pass của https://fastsminingpro.net
BJuxt9ltbYSmnij


thêm chức năng danh mục ảnh
thêm sáng tôi



tạo signingConfigs để bảo về bản release 

open powershell: 
-> keytool -genkey -v -keystore my-release-key.keystore -alias my-key-alias -keyalg RSA -keysize 2048 -validity 10000

sau khi tạo keytool xong cần lấy -> SHA-1 và SHA-256 bằng lệnh bên dưới
-> keytool -list -v -keystore my-release-key.keystore -alias my-key-alias


Bước 1: Đặt file keystore vào dự án
Sau khi tạo file my-release-key.keystore, hãy di chuyển nó vào thư mục android/app trong dự án của bạn (ví dụ: D:\Fluter\newv0\flutter_application_2\android\app).

Điều này giúp Gradle dễ dàng truy cập file khi build.





Bước 2: truy cập vào: D:\Fluter\newv0\flutter_application_2\android\app\build.gradle.kts thêm dữ liệu sau


// Thêm cấu hình signingConfigs
signingConfigs {
    create("release") {
        storeFile = file("my-release-key.keystore") // File trong android/app
        storePassword = "giakhanh123"               // Mật khẩu keystore bạn đã nhập
        keyAlias = "my-key-alias"                   // Alias từ lệnh keytool
        keyPassword = "giakhanh123"                 // Mật khẩu key bạn đã nhập
    }
}
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }
}

