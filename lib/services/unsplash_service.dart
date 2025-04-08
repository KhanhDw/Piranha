import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_2/models/UnsplashPhoto.dart';

class UnsplashService {
  static const String accessKey = 'cpFclLJmwaUkLKKn868ZTKc05aEsDcswKadrEEP5bN0';
  static const String baseUrl = 'https://api.unsplash.com';

  Future<List<UnsplashPhoto>> fetchPhotos({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/photos?page=$page&per_page=20&client_id=$accessKey'),
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);

      if (jsonResponse.isEmpty) {
        return [];
      }

      return jsonResponse.map((data) => UnsplashPhoto.fromJson(data)).toList();
    } else {
      // throw Exception(
      //   'Failed to load photos from Unsplash: ${response.statusCode}',
      // );
      return [];
    }
  }
}
