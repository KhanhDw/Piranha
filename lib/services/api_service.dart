import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_2/models/PexelsPhoto.dart';

class ApiService {
  static const String apiKey =
      'dDVuxlGhTXGij3jGNu9Xaka2RlhkilhiFUpCkI41wQhpAIxQCz9liPr1';
  static const String baseUrl = 'https://api.pexels.com/v1';

  Future<List<PexelsPhoto>> fetchPhotos({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/curated?per_page=20&page=$page'),
      headers: {'Authorization': apiKey},
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      List photos = jsonResponse['photos'];

      if (photos.isEmpty) {
        return [];
      }

      return photos.map((data) => PexelsPhoto.fromJson(data)).toList();
    } else {
      // throw Exception(
      //   'Failed to load photos from Pexels: ${response.statusCode} - ${response.body}',
      // );
      return [];
    }
  }
}
