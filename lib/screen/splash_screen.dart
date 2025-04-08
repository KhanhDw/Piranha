import 'package:flutter/material.dart';
import '../main.dart'; // Để truy cập PhotoListScreen
import 'package:flutter_application_2/services/unsplash_service.dart';
import 'package:flutter_application_2/services/api_service.dart';
import 'package:flutter_application_2/models/UnsplashPhoto.dart';
import 'package:flutter_application_2/models/PexelsPhoto.dart';
import 'dart:math';
import 'package:logger/logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final logger = Logger();
  List<dynamic> initialPhotos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Tải dữ liệu khi splash screen bắt đầu
  }

  Future<void> _loadInitialData() async {
    try {
      int pageNumberUnslash = Random().nextInt(150) + 1;
      int pageNumberPexel = Random().nextInt(150) + 1;

      // Tải dữ liệu từ Unsplash và Pexels
      List<UnsplashPhoto> unsplashPhotos = await UnsplashService().fetchPhotos(
        page: pageNumberUnslash,
      );
      List<PexelsPhoto> pexelsPhotos = await ApiService().fetchPhotos(
        page: pageNumberPexel,
      );

      // Cập nhật danh sách ảnh
      initialPhotos.addAll(pexelsPhotos);
      initialPhotos.addAll(unsplashPhotos);

      // Đảm bảo vòng tròn hiển thị ít nhất 2.5 giây
      await Future.wait([
        Future.delayed(
          const Duration(milliseconds: 2500),
        ), // Vòng tròn tồn tại 2.5s
        Future.value(), // Đảm bảo dữ liệu đã tải xong
      ]);

      // Sau 3 giây tổng cộng, chuyển màn hình
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Đợi thêm 0.5s để đủ 3s

      setState(() {
        isLoading = false;
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoListScreen(initialPhotos: initialPhotos),
          ),
        );
      }
    } catch (e) {
      logger.e("Error loading initial photos: $e");

      // Đảm bảo vòng tròn hiển thị ít nhất 2.5 giây dù có lỗi
      await Future.wait([
        Future.delayed(
          const Duration(milliseconds: 2500),
        ), // Vòng tròn tồn tại 2.5s
      ]);

      // Sau 3 giây tổng cộng, chuyển màn hình dù lỗi
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Đợi thêm 0.5s để đủ 3s

      setState(() {
        isLoading = false;
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoListScreen(initialPhotos: initialPhotos),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Ảnh splash full màn hình
          SizedBox.expand(
            child: Image.asset('assets/splash.png', fit: BoxFit.cover),
          ),
          // Hiển thị thông báo và vòng tròn khi đang tải
          if (isLoading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 50, // Cách đáy màn hình 50px
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(
                    height: 10,
                  ), // Khoảng cách giữa vòng tròn và text
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6), // Nền mờ để dễ đọc
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Đang tải hệ thống',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
