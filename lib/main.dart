import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screen/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screen/photo_list_screen.dart';

void main() async
{
  try
  {
    WidgetsFlutterBinding.ensureInitialized();
    MobileAds.instance.initialize();
    await Firebase.initializeApp(); // Khởi tạo Firebase
    runApp(const MyApp());
  }
  catch (e)
  {
    print('Lỗi xảy ra: $e');
  }
}

// =========================================
//  my app screen
// =========================================

class MyApp extends StatefulWidget
{
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>
{
  @override
  void initState()
  {
    super.initState();
  }

  @override
  Widget build(BuildContext context)
  {

    return MaterialApp(
      title: 'Photo App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(), // Hiển thị splash screen đầu tiên
      debugShowCheckedModeBanner: false
    );
  }
}
