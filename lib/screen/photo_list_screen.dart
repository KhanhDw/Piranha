
import 'package:flutter_application_2/services/unsplash_service.dart';
import 'package:flutter_application_2/models/UnsplashPhoto.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screen/photo_detail_screen.dart';
import '../screen/overview_screen.dart';
import 'package:flutter/material.dart';
import '../screen/ad_logs_screen.dart'; // Import màn hình nhật ký
import '../session/user_session.dart';
import '../services/api_service.dart';
import '../screen/login_screen.dart';
import 'package:logger/logger.dart';
import '../models/PexelsPhoto.dart';
import 'dart:convert';
import 'dart:math';


// =========================================
//  photo list screen
// =========================================

class PhotoListScreen extends StatefulWidget
{
  final List<dynamic> initialPhotos; // Thêm tham số để nhận dữ liệu ban đầu
  const PhotoListScreen({super.key, this.initialPhotos = const[]});

  @override
  _PhotoListScreenState createState() => _PhotoListScreenState();
}

class _PhotoListScreenState extends State<PhotoListScreen>
{
  final logger = Logger();
  List<dynamic> photos = [];
  int pageNumberPexel = 1;
  int pageNumberUnslash = 1;
  int maxRandom = 150;
  bool isLoading = false;
  bool isProcessing = false; // Biến để khóa nút khi đang xử lý
  late ScrollController _scrollController;

  // Quảng cáo Banner
  late BannerAd _bannerAd;
  bool _isBannerAdLoaded = false;
  final String _adUnitIdRealBanner = 'ca-app-pub-4590752034914989/5961673035';

  @override
  void initState() 
  {
    super.initState();
    photos = List.from(widget.initialPhotos);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    if (photos.isEmpty) 
    {
      _loadMorePhotos();
    }

    _loadBannerADS();
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async
  {
    final prefs = await SharedPreferences.getInstance();
    setState(()
      {
        UserSession.userId = prefs.getString('userId') ?? '';
        UserSession.email = prefs.getString('email') ?? '';
        UserSession.userName = prefs.getString('userName') ?? '';
      }
    );
  }

  // Hàm kiểm tra trạng thái đăng nhập
  bool _isUserLoggedIn() 
  {
    return FirebaseAuth.instance.currentUser != null ||
      (UserSession.email?.isNotEmpty ?? false);
  }

  _loadBannerADS() 
  {
    _bannerAd = BannerAd(
      adUnitId: _adUnitIdRealBanner,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad)
        {
          setState(()
            {
              _isBannerAdLoaded = true;
            }
          );
          debugPrint("Banner Ad loaded successfully");
        },
        onAdFailedToLoad: (ad, error)
        {
          logger.i('Failed to load banner ad: $error');
          ad.dispose();
        }
      )
    );
    _bannerAd.load();
  }

  @override
  void dispose() 
  {
    _scrollController.dispose();
    _bannerAd.dispose();
    super.dispose();
  }

  void _scrollListener() 
  {
    if (_scrollController.position.pixels >=
      _scrollController.position.maxScrollExtent - 1200 &&
      !isLoading) 
    {
      setState(()
        {
          isLoading = true;
        }
      );
      _loadMorePhotos();
    }
  }

  Future<void> _loadMorePhotos() async
  {
    setState(()
      {
        isLoading = true;
      }
    );

    pageNumberUnslash = generateRandomNumber(min: 1, max: maxRandom);
    pageNumberPexel = generateRandomNumber(min: 1, max: maxRandom);

    int attempts = 0;
    while (attempts < 3)
    {
      try
      {
        List<UnsplashPhoto> unsplashPhotos =
          await UnsplashService().fetchPhotos(page: pageNumberUnslash);
        List<PexelsPhoto> pexelsPhotos =
          await ApiService().fetchPhotos(page: pageNumberPexel);

        if (unsplashPhotos.isEmpty && pexelsPhotos.isEmpty) 
        {
          attempts++;
          pageNumberUnslash = generateRandomNumber(min: 1, max: maxRandom);
          pageNumberPexel = generateRandomNumber(min: 1, max: maxRandom);
          continue;
        }

        setState(()
          {
            photos.addAll(pexelsPhotos);
            photos.addAll(unsplashPhotos);
            pageNumberUnslash++;
            pageNumberPexel++;
            isLoading = false;
          }
        );

        break;
      }
      catch (e)
      {
        logger.e("Error loading photos: $e");
        setState(()
          {
            isLoading = false;
          }
        );
        break;
      }
    }

    if (attempts == 3) 
    {
      setState(()
        {
          isLoading = false;
        }
      );
      logger.e("Failed to load photos after multiple attempts.");
    }
  }

  @override
  Widget build(BuildContext context) 
  {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Piranha'),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold
          ),
          backgroundColor: const Color.fromARGB(255, 19, 20, 29),
          actions: [
            IconButton(
              onPressed: isProcessing
                ? null // Vô hiệu hóa nút khi đang xử lý
                : () async
                {
                  setState(()
                    {
                      isProcessing = true; // Khóa nút
                    }
                  );

                  if (!_isUserLoggedIn()) 
                  {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen())
                    ).then((_)
                        {
                          // Reload trạng thái sau khi quay lại từ LoginScreen
                          _loadUserFromPrefs();
                        }
                      );
                  }
                  else 
                  {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Overview())
                    ).then((_)
                        {
                          // Reload trạng thái sau khi quay lại từ Overview
                          _loadUserFromPrefs();
                        }
                      );
                  }

                  setState(()
                    {
                      isProcessing = false; // Mở khóa nút
                    }
                  );
                },
              icon: Icon(
                _isUserLoggedIn() ? Icons.view_headline_rounded : Icons.person,
                color: Colors.white
              )
            )
          ]
        ),
        backgroundColor: const Color.fromARGB(255, 36, 39, 63),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: GridView.builder(
                  controller: _scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4
                  ),
                  itemCount: photos.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index)
                  {
                    if (index < photos.length) 
                    {
                      return GestureDetector(
                        onTap: ()
                        {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              PhotoDetailScreen(photo: photos[index])
                            )
                          );
                        },
                        child: Hero(
                          tag: 'photo_${photos[index].id}',
                          child: CachedNetworkImage(
                            imageUrl: photos[index].imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                            const Icon(Icons.error, color: Colors.red)
                          )
                        )
                      );
                    }
                    else if (isLoading) 
                    {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return const SizedBox.shrink();
                  }
                )
              )
            ),
            if (_isBannerAdLoaded)
            Container(
              height: _bannerAd.size.height.toDouble(),
              width: _bannerAd.size.width.toDouble(),
              alignment: Alignment.center,
              child: AdWidget(ad: _bannerAd)
            )
          ]
        )
      )
    );
  }

  // lưu trữ dữ liệu cục bộ
  Future<void> logAdImpression(String userId) async
  {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    final log = prefs.getStringList('ad_logs') ?? [];
    log.add(jsonEncode({'userId': userId, 'timestamp': now}));
    await prefs.setStringList('ad_logs', log);
  }

  int generateRandomNumber({int min = 0, int? max}) 
  {
    final random = Random();
    if (max == null) 
    {
      // Nếu không có max, trả về số nguyên dương ngẫu nhiên
      return random.nextInt(2147483647); // Giá trị max của int32
    }
    else 
    {
      // Trả về số nguyên ngẫu nhiên trong khoảng [min, max)
      return min + random.nextInt(max - min);
    }
  }
}
