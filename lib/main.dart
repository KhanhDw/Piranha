import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_2/models/UnsplashPhoto.dart';
import 'services/api_service.dart';
import 'models/PexelsPhoto.dart';
import 'screen/photo_detail_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'screen/ad_logs_screen.dart'; // Import màn hình nhật ký
import 'package:flutter_application_2/services/unsplash_service.dart';
import 'dart:math';
import 'screen/overview_screen.dart';
import 'screen/login_screen.dart';
import 'session/user_session.dart';
import 'package:logger/logger.dart';
import 'screen/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    MobileAds.instance.initialize();
    await Firebase.initializeApp(); // Khởi tạo Firebase
    runApp(const MyApp());
  } catch (e) {
    print('Lỗi xảy ra: $e');
  }
}

// =========================================
//  my app screen
// =========================================

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Thêm điều hướng sau khi build hoàn tất
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Kiểm tra xem widget còn tồn tại không
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PhotoListScreen()),
        );
      }
    });

    return MaterialApp(
      title: 'Photo App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(), // Hiển thị splash screen đầu tiên
      debugShowCheckedModeBanner: false,
    );
  }
}

// =========================================
//  photo list screen
// =========================================

class PhotoListScreen extends StatefulWidget {
  final List<dynamic> initialPhotos; // Thêm tham số để nhận dữ liệu ban đầu
  const PhotoListScreen({super.key, this.initialPhotos = const []});

  @override
  _PhotoListScreenState createState() => _PhotoListScreenState();
}

class _PhotoListScreenState extends State<PhotoListScreen> {
  final logger = Logger();

  List<dynamic> photos = [];
  int pageNumberPexel = 1;
  int pageNumberUnslash = 1;
  int maxRandom = 150;
  bool isLoading = false;
  late ScrollController _scrollController;
  // user logic
  final int userId = -1;
  final String email = '';
  bool isLogic = false;

  // Quảng cáo Banner
  late BannerAd _bannerAd;
  bool _isBannerAdLoaded = false;

  // ID đơn vị quảng cáo thử nghiệm cho banner
  final String _adUnitIdTestBanner =
      'ca-app-pub-3940256099942544/6300978111'; // Android

  // ID đơn vị quảng cáo thật cho banner - quảng cáo 1
  final String _adUnitIdRealBanner =
      'ca-app-pub-4590752034914989/5961673035'; // ads Android real ☆

  @override
  void initState() {
    super.initState();

    // Khởi tạo photos với dữ liệu ban đầu từ SplashScreen
    photos = List.from(widget.initialPhotos);

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    if (photos.isEmpty) {
      _loadMorePhotos(); // Nếu không có dữ liệu ban đầu, tải thêm
    }
    _loadBannerADS();
    _loadUserFromPrefs();
  }

  _loadBannerADS() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitIdRealBanner, // Thay thế bằng Ad Unit ID của bạn ☆
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
          debugPrint("Banner Ad loaded successfully");
          AdLogsScreen.logAdImpression('Trang chủ');
        },
        onAdFailedToLoad: (ad, error) {
          logger.i('Failed to load banner ad: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd.load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bannerAd.load();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 1200 &&
        !isLoading) {
      setState(() {
        isLoading = true; // Đặt lại isLoading trước khi tải ảnh mới
      });
      _loadMorePhotos();
    }
  }

  Future<void> _loadMorePhotos() async {
    setState(() {
      isLoading = true; // Đặt isLoading = true trước khi tải ảnh mới
    });

    // Tạo số trang ngẫu nhiên
    pageNumberUnslash = generateRandomNumber(min: 1, max: maxRandom);
    pageNumberPexel = generateRandomNumber(min: 1, max: maxRandom);

    int attempts = 0; // Biến để giới hạn số lần gọi API

    while (attempts < 3) {
      // Giới hạn 3 lần thử
      try {
        // Gửi yêu cầu fetch ảnh từ Unsplash và Pexels
        List<UnsplashPhoto> unsplashPhotos = await UnsplashService()
            .fetchPhotos(page: pageNumberUnslash);
        List<PexelsPhoto> pexelsPhotos = await ApiService().fetchPhotos(
          page: pageNumberPexel,
        );

        // Nếu cả 2 API đều trả về ảnh trống, thử lại
        if (unsplashPhotos.isEmpty && pexelsPhotos.isEmpty) {
          attempts++; // Tăng số lần thử
          pageNumberUnslash = generateRandomNumber(
            min: 1,
            max: maxRandom,
          ); // Chọn trang ngẫu nhiên khác
          pageNumberPexel = generateRandomNumber(min: 1, max: maxRandom);
          continue; // Tiếp tục thử tải lại ảnh
        }

        // Nếu có ảnh trả về
        setState(() {
          photos.addAll(pexelsPhotos);
          photos.addAll(unsplashPhotos);
          pageNumberUnslash++;
          pageNumberPexel++;
          isLoading = false;
        });

        break; // Nếu tải thành công, thoát khỏi vòng lặp
      } catch (e) {
        logger.e("Error loading photos: $e");
        setState(() {
          isLoading = false;
        });
        break; // Thoát khỏi vòng lặp nếu có lỗi xảy ra
      }
    }

    // Nếu sau 3 lần thử mà vẫn không có ảnh, bạn có thể xử lý như thông báo lỗi
    if (attempts == 3) {
      setState(() {
        isLoading = false;
      });
      logger.e("Failed to load photos after multiple attempts.");
    }
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    UserSession.userId = prefs.getString('userId');
    UserSession.email = prefs.getString('email');
  }

  @override
  Widget build(BuildContext context) {
    final email = UserSession.email ?? '';

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
            IconButton(
              onPressed: () {
                if (email.isEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Overview()),
                  );
                }
              },

              icon: Icon(
                email.isEmpty ? Icons.person : Icons.view_headline_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 36, 39, 63),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(4),
                child: GridView.builder(
                  controller: _scrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount:
                      photos.length +
                      (isLoading ? 1 : 0), // Thêm một phần tử cho khi đang tải
                  itemBuilder: (context, index) {
                    if (index < photos.length) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      PhotoDetailScreen(photo: photos[index]),
                            ),
                          );
                        },
                        child: Hero(
                          tag:
                              'photo_${photos[index].id}', // Hiệu ứng mượt mà khi mở ảnh
                          child: CachedNetworkImage(
                            imageUrl: photos[index].imageUrl,
                            fit: BoxFit.cover, // Hiển thị ảnh đúng tỉ lệ
                            placeholder:
                                (context, url) =>
                                    Center(child: CircularProgressIndicator()),
                            errorWidget:
                                (context, url, error) =>
                                    Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                      );
                    } else if (isLoading) {
                      return Center(
                        child: CircularProgressIndicator(),
                      ); // Đang tải thêm ảnh
                    }
                    return SizedBox.shrink(); // Không hiển thị gì nếu không có ảnh và không tải
                  },
                ),
              ),
            ),

            if (_isBannerAdLoaded)
              Container(
                height:
                    _bannerAd.size.height
                        .toDouble(), // Đảm bảo chiều cao khớ với banner,
                width: _bannerAd.size.width.toDouble(),
                alignment: Alignment.center, // Hiển thị banner
                child: AdWidget(
                  ad: _bannerAd,
                ), // Chiều cao của quảng cáo banner
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

  int generateRandomNumber({int min = 0, int? max}) {
    final random = Random();
    if (max == null) {
      // Nếu không có max, trả về số nguyên dương ngẫu nhiên
      return random.nextInt(2147483647); // Giá trị max của int32
    } else {
      // Trả về số nguyên ngẫu nhiên trong khoảng [min, max)
      return min + random.nextInt(max - min);
    }
  }
}
