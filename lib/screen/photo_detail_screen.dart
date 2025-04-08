import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import '../models/PexelsPhoto.dart'; // Giả sử bạn đã định nghĩa model Photo
import '../models/UnsplashPhoto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_logs_screen.dart'; // Import màn hình nhật ký
import 'dart:convert';

class PhotoDetailScreen extends StatefulWidget {
  final dynamic photo; // cần thay đổi để nhận được thêm unslash

  const PhotoDetailScreen({required this.photo, super.key});

  @override
  _PhotoDetailScreenState createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late BannerAd _bannerAd2;
  bool _isBanner2AdLoaded = false;

  // --- Các biến trạng thái để lưu thông tin ảnh ---
  String _imageUrl = '';
  String _photographerName = 'Unknown';
  String _downloadUrl = '';
  dynamic _photoIdentifier; // int (Pexels) or String (Unsplash)
  bool _isValidPhoto = false;
  // ---------------------------------------------

  // ID đơn vị quảng cáo thử nghiệm cho banner
  final String _adUnitIdTestBanner =
      'ca-app-pub-3940256099942544/6300978111'; // Android
  // ID đơn vị quảng cáo thật cho banner
  final String _adUnitIdRealBanner =
      'ca-app-pub-4590752034914989/1520876903'; // Thay bằng ID thật của bạn

  @override
  void initState() {
    super.initState();
    _extractPhotoInfo(); // Trích xuất thông tin dựa trên model
    _loadBannerAd();
  }

  void _extractPhotoInfo() {
    if (widget.photo is PexelsPhoto) {
      final pexelsPhoto = widget.photo as PexelsPhoto;
      // Sử dụng các trường từ PexelsPhoto model của bạn
      _imageUrl = pexelsPhoto.imageUrl; // -> src.large2x / src.original
      _photographerName = pexelsPhoto.photographer; // -> photographer
      _downloadUrl = pexelsPhoto.downloadUrl; // -> src.original
      _photoIdentifier = pexelsPhoto.id; // -> id (int)
      _isValidPhoto = true;
      print("Photo Type: Pexels");
    } else if (widget.photo is UnsplashPhoto) {
      final unsplashPhoto = widget.photo as UnsplashPhoto;
      // Sử dụng các trường từ UnsplashPhoto model của bạn
      _imageUrl = unsplashPhoto.imageUrl; // -> urls.regular
      _photographerName = unsplashPhoto.photographer; // -> user.name
      _downloadUrl = unsplashPhoto.downloadUrl; // -> links.download
      _photoIdentifier = unsplashPhoto.id; // -> id (String)
      _isValidPhoto = true;
      print("Photo Type: Unsplash");
      // Lưu ý: Unsplash có thể yêu cầu trigger download qua `links.download_location`
      // Bạn có thể cần thêm logic đó nếu download trực tiếp `links.download` không hoạt động
      // hoặc để tuân thủ chính sách API của họ.
    } else {
      _isValidPhoto = false;
      print(
        "Error: Invalid photo type passed to PhotoDetailScreen. Type was: ${widget.photo?.runtimeType}",
      );
    }
  }

  _loadBannerAd() {
    // Khởi tạo quảng cáo Banner
    _bannerAd2 = BannerAd(
      adUnitId:
          _adUnitIdRealBanner, // Thay bằng _adUnitIdRealBanner/ _adUnitIdTestBanner khi phát hành
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
          ad.dispose();
        },
      ),
    );
    _bannerAd2.load(); // Tải quảng cáo
  }

  @override
  void dispose() {
    _bannerAd2.dispose(); // Giải phóng tài nguyên quảng cáo khi thoát màn hình
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy URL để tải xuống.')),
        );
      }
      return;
    }

    PermissionStatus status;
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        status = PermissionStatus.granted;
      } else {
        status = await Permission.manageExternalStorage.request();
      }
    } else {
      status = await Permission.storage.request();
    }

    if (!status.isGranted) {
      if (status.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quyền lưu trữ bị từ chối')),
        );
      } else if (status.isPermanentlyDenied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Quyền lưu trữ bị từ chối vĩnh viễn. Vui lòng bật nó trong cài đặt ứng dụng.',
              ),
              action: SnackBarAction(
                label: 'Mở Cài đặt',
                onPressed: openAppSettings,
              ),
            ),
          );
          openAppSettings();
        }
      }
      return;
    }

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Chọn thư mục để lưu ảnh',
      );

      if (selectedDirectory == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Hủy chọn thư mục')));
        }
        return;
      }

      final fileName = '$identifier_photo.jpg';
      final filePath = path.join(selectedDirectory, fileName);
      final dio = Dio();
      final cancelToken = CancelToken();

      double progress = 0.0;

      // Mở dialog hiện tiến trình tải
      if (context.mounted) {
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
      }

      // Tiến hành tải ảnh
      await dio.download(
        downloadUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            double newProgress = received / total;
            progress = newProgress;

            // Cập nhật lại dialog
            if (context.mounted) {
              // Tìm dialog và cập nhật
              (context as Element).markNeedsBuild();
            }
          }
        },
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Đóng dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tải xuống ảnh vào $filePath')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Đóng dialog nếu đang mở
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Tải xuống thất bại: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nếu không có thông tin ảnh hợp lệ, hiển thị trạng thái lỗi/loading
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
                placeholder:
                    (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                errorWidget:
                    (context, url, error) =>
                        const Center(child: Icon(Icons.error, size: 50)),
              ),
            ),

            if (_isBanner2AdLoaded)
              Container(
                alignment: Alignment.center,
                width: _bannerAd2.size.width.toDouble(),
                height:
                    _bannerAd2.size.height
                        .toDouble(), // Đảm bảo chiều cao khớp với banner
                child: AdWidget(ad: _bannerAd2),
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
