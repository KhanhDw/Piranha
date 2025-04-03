import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
// import 'package:path_provider/path_provider.dart';
import 'models/photo.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

class PhotoDetailScreen extends StatelessWidget {
  final Photo photo;

  const PhotoDetailScreen({required this.photo, super.key});

  Future<void> downloadImage(BuildContext context, String downloadUrl, int photoId) async {
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

  if (status.isGranted) {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hủy chọn thư mục')),
        );
        return;
      }

      final filePath = path.join(selectedDirectory, '$photoId.jpg');
      final dio = Dio(BaseOptions(receiveTimeout: const Duration(seconds: 30)));
      final cancelToken = CancelToken();
      int lastProgress = 0;

      await dio.download(
        downloadUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            final progressInt = int.parse(progress);
            if (progressInt - lastProgress >= 10 || progressInt == 100) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đang tải xuống $progress%')),
              );
              lastProgress = progressInt;
            }
          }
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tải xuống ảnh vào $filePath')),
      );
    } catch (e) {
      print('Tải xuống thất bại: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tải xuống thất bại: ${e.toString()}')),
      );
    }
  } else if (status.isDenied) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quyền lưu trữ bị từ chối')),
    );
  } else if (status.isPermanentlyDenied) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Quyền lưu trữ bị từ chối vĩnh viễn. Vui lòng bật nó trong cài đặt ứng dụng.')),
    );
    openAppSettings();
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 36, 39, 63), // Thay đổi màu nền ở đây
      body: Stack(
        children: [
          SizedBox.expand(
            child: CachedNetworkImage(
              imageUrl: photo.imageUrl,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high, 
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
                  const Center(child: Icon(Icons.error, size: 50)),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor:  const Color.fromARGB(255, 36, 39, 63), // Thay đổi màu nền ở đây,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: () {
                    downloadImage(context, photo.downloadUrl, photo.id); // Gọi hàm với đủ tham số
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}