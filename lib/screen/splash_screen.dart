import 'package:flutter/material.dart';
import 'package:flutter_application_2/services/unsplash_service.dart';
import 'package:flutter_application_2/services/api_service.dart';
import 'package:flutter_application_2/models/UnsplashPhoto.dart';
import 'package:flutter_application_2/models/PexelsPhoto.dart';
import 'dart:math';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'photo_list_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final logger = Logger();
  List<dynamic> initialPhotos = [];
  bool isLoading = false; // Chỉ hiển thị giao diện splash khi cần

  @override
  void initState() {
    super.initState();
    _initializeApp(); // Kiểm tra trạng thái và xử lý
  }

  Future<void> _initializeApp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstLoad = prefs.getBool('isFirstLoad') ?? true;
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isFirstLoad) {
      // Lần đầu chạy: hiển thị splash và tải dữ liệu
      setState(() {
        isLoading = true;
      });
      await _loadInitialData();
      await prefs.setBool('isFirstLoad', false); // Đánh dấu đã tải lần đầu
    } else {
      // Không phải lần đầu: chuyển thẳng đến PhotoListScreen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => PhotoListScreen(initialPhotos: initialPhotos)),
        );
      }
    }
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
        Future.delayed(const Duration(milliseconds: 2500)), // Vòng tròn tồn tại 2.5s
        Future.value(), // Đảm bảo dữ liệu đã tải xong
      ]);

      // Sau 3 giây tổng cộng, chuyển màn hình
      await Future.delayed(const Duration(milliseconds: 500)); // Đợi thêm 0.5s để đủ 3s

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
        Future.delayed(const Duration(milliseconds: 2500)), // Vòng tròn tồn tại 2.5s
      ]);

      // Sau 3 giây tổng cộng, chuyển màn hình dù lỗi
      await Future.delayed(const Duration(milliseconds: 500)); // Đợi thêm 0.5s để đủ 3s

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoListScreen(initialPhotos: initialPhotos)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? Stack(
              children: [
                // Ảnh splash full màn hình
                SizedBox.expand(
                  child: Image.asset('assets/splash.png', fit: BoxFit.cover),
                ),
                // Hiển thị thông báo và vòng tròn khi đang tải
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
                      const SizedBox(height: 10), // Khoảng cách giữa vòng tròn và text
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            )
          : const Center(child: CircularProgressIndicator()), // Hiển thị loading nhẹ khi chuyển màn
    );
  }
}