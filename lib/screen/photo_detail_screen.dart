import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import '../models/PexelsPhoto.dart';
import '../models/UnsplashPhoto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_logs_screen.dart';
import 'dart:convert';

class PhotoDetailScreen extends StatefulWidget {
  final dynamic photo;

  const PhotoDetailScreen({required this.photo, super.key});

  @override
  _PhotoDetailScreenState createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  BannerAd? _bannerAd2; // Thay đổi thành nullable để kiểm soát tốt hơn
  bool _isBanner2AdLoaded = false;

  String _imageUrl = '';
  String _downloadUrl = '';
  dynamic _photoIdentifier;
  bool _isValidPhoto = false;

  final String _adUnitIdRealBanner = 'ca-app-pub-4590752034914989/1520876903';

  @override
  void initState() {
    super.initState();
    _extractPhotoInfo();
    _initializeBannerAd(); // Tách logic khởi tạo quảng cáo
  }

  void _extractPhotoInfo() {
    if (widget.photo is PexelsPhoto) {
      final pexelsPhoto = widget.photo as PexelsPhoto;
      _imageUrl = pexelsPhoto.imageUrl;
      _downloadUrl = pexelsPhoto.downloadUrl;
      _photoIdentifier = pexelsPhoto.id;
      _isValidPhoto = true;
      print("Photo Type: Pexels");
    } else if (widget.photo is UnsplashPhoto) {
      final unsplashPhoto = widget.photo as UnsplashPhoto;
      _imageUrl = unsplashPhoto.imageUrl;
      _downloadUrl = unsplashPhoto.downloadUrl;
      _photoIdentifier = unsplashPhoto.id;
      _isValidPhoto = true;
      print("Photo Type: Unsplash");
    } else {
      _isValidPhoto = false;
      print("Error: Invalid photo type: ${widget.photo?.runtimeType}");
    }
  }

  void _initializeBannerAd() {
    // Chỉ khởi tạo và tải quảng cáo nếu chưa có
    if (_bannerAd2 == null) {
      _loadBannerAd();
    } else if (!_isBanner2AdLoaded) {
      _bannerAd2!.load(); // Tải lại nếu đã có instance nhưng chưa load
    }
  }

  void _loadBannerAd() {
    _bannerAd2 = BannerAd(
      adUnitId: _adUnitIdRealBanner,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBanner2AdLoaded = true;
          });
          print("Banner Ad loaded successfully");
          AdLogsScreen.logAdImpression('Trang chi tiết ảnh');
        },
        onAdFailedToLoad: (ad, error) {
          print('Failed to load banner ad: $error');
          // Không dispose ở đây để giữ instance, có thể thử tải lại sau
        },
      ),
    );
    _bannerAd2!.load();
  }

  @override
  void dispose() {
    // Không dispose _bannerAd2 để giữ quảng cáo tồn tại
    super.dispose();
  }

  Future<void> downloadImage(
    BuildContext context,
    String downloadUrl,
    Object photoIdentifier,
  ) async {
    String identifier_photo;
    if (photoIdentifier is int) {
      identifier_photo = photoIdentifier.toString();
    } else if (photoIdentifier is String) {
      identifier_photo = photoIdentifier;
    } else {
      throw ArgumentError('photoIdentifier phải là int hoặc String');
    }

    if (downloadUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy URL để tải xuống.')),
      );
      return;
    }

    PermissionStatus status;
    if (Platform.isAndroid) {
      status = await Permission.manageExternalStorage.request();
    } else {
      status = await Permission.storage.request();
    }

    if (!status.isGranted) {
      if (status.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quyền lưu trữ bị từ chối')),
        );
      } else if (status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Quyền lưu trữ bị từ chối vĩnh viễn. Vui lòng bật trong cài đặt.',
            ),
            action: SnackBarAction(
              label: 'Mở Cài đặt',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
      return;
    }

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Chọn thư mục để lưu ảnh',
      );

      if (selectedDirectory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hủy chọn thư mục')),
        );
        return;
      }

      final fileName = '$identifier_photo.jpg';
      final filePath = path.join(selectedDirectory, fileName);
      final dio = Dio();
      final cancelToken = CancelToken();

      double progress = 0.0;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text("Đang tải ảnh..."),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 10),
                    Text('${(progress * 100).toStringAsFixed(0)}%'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      cancelToken.cancel();
                      Navigator.of(context).pop();
                    },
                    child: const Text("Huỷ"),
                  ),
                ],
              );
            },
          );
        },
      );

      await dio.download(
        downloadUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            progress = received / total;
            (context as Element).markNeedsBuild();
          }
        },
      );

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tải xuống ảnh vào $filePath')),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tải xuống thất bại: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isValidPhoto) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: const Center(
          child: Text('Không thể tải thông tin chi tiết ảnh.'),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 106, 112, 159),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: () {
                downloadImage(context, _downloadUrl, _photoIdentifier);
              },
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 36, 39, 63),
        body: Column(
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: _imageUrl,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                    const Center(child: Icon(Icons.error, size: 50)),
              ),
            ),
            if (_isBanner2AdLoaded && _bannerAd2 != null)
              Container(
                alignment: Alignment.center,
                width: _bannerAd2!.size.width.toDouble(),
                height: _bannerAd2!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd2!),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> logAdImpression(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    final log = prefs.getStringList('ad_logs') ?? [];
    log.add(jsonEncode({'userId': userId, 'timestamp': now}));
    await prefs.setStringList('ad_logs', log);
  }
}