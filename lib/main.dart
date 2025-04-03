import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'services/api_service.dart';
import 'models/photo.dart';
import 'photo_detail_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_logs_screen.dart'; // Import màn hình nhật ký

void main() {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    MobileAds.instance.initialize();
    runApp(MyApp());
  } catch (e) {
    print('Lỗi xảy ra: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PhotoListScreen(),
    );
  }
}

class PhotoListScreen extends StatefulWidget {
  const PhotoListScreen({super.key});

  @override
  _PhotoListScreenState createState() => _PhotoListScreenState();
}

class _PhotoListScreenState extends State<PhotoListScreen> {
  List<Photo> photos = [];
  int page = 1;
  bool isLoading = false;
  late ScrollController _scrollController;

  // Quảng cáo Banner
  late BannerAd _bannerAd;
  bool _isBannerAdLoaded = false;

   // ID đơn vị quảng cáo thử nghiệm cho banner
  final String _adUnitIdTestBanner = 'ca-app-pub-3940256099942544/6300978111'; // Android
  // Sử dụng 'ca-app-pub-3940256099942544/2934735716' cho iOS

  // ID đơn vị quảng cáo thật cho banner - quảng cáo 1
  final String _adUnitIdRealBanner = 'ca-app-pub-4590752034914989/5961673035'; // ads Android real ☆

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener); 
    _loadMorePhotos();

    // Khởi tạo quảng cáo Banner
    _bannerAd = BannerAd(
      adUnitId: _adUnitIdTestBanner, // Thay thế bằng Ad Unit ID của bạn ☆
      size: AdSize.banner, // Kích thước banner
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
          print("Banner Ad loaded successfully");
          logAdImpression('user_123'); // Gọi hàm logAdImpression với userId
        },
        onAdFailedToLoad: (ad, error) {
          print('Failed to load banner ad: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd.load(); // Tải quảng cáo
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bannerAd.dispose(); // Giải phóng tài nguyên khi không sử dụng quảng cáo nữa
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !isLoading) {
      _loadMorePhotos();
    }
  }

  Future<void> _loadMorePhotos() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Photo> newPhotos = await ApiService().fetchPhotos(page: page);
      if (newPhotos.isNotEmpty) {
        setState(() {
          photos.addAll(newPhotos);
          page++;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading more photos: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Piranha'),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: const Color.fromARGB(255, 19, 20, 29),
           actions: [
                ElevatedButton(
                  onPressed: () { Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdLogsScreen()),
                  );
                },
                child: Text('Logs'),
                ),
              ],
        ),
        backgroundColor: const Color.fromARGB(255, 36, 39, 63),
        body: Stack( // Sử dụng Stack để thêm quảng cáo banner vào cuối màn hình
          children: [
            GridView.builder(
              controller: _scrollController,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: photos.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < photos.length) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhotoDetailScreen(photo: photos[index]),
                        ),
                      );
                    },
                    child: CachedNetworkImage(
                      imageUrl: photos[index].imageUrl,
                      placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  );
                } else if (isLoading) {
                  return Center(child: CircularProgressIndicator());
                }
                return null;
              },
            ),
            if (_isBannerAdLoaded)
              Positioned(
                bottom: 0, // Đặt quảng cáo ở cuối cùng màn hình
                left: 0,
                right: 0,
                child: Container(
                  alignment: Alignment.center, // Hiển thị banner
                  height: 50,
                  child: AdWidget(ad: _bannerAd), // Chiều cao của quảng cáo banner
                ),
              ),
          ],
        ),
      ),
    );
  }

  // lưu trữ dữ liệu cục bộ
  Future<void> logAdImpression(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    final log = prefs.getStringList('ad_logs') ?? [];
    log.add(jsonEncode({'userId': userId, 'timestamp': now}));
    await prefs.setStringList('ad_logs', log);
  }
}
