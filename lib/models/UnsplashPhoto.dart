class UnsplashPhoto {
  final String id;
  final String photographer;
  final String imageUrl;
  final String downloadUrl;
  final String url; // Đường dẫn gốc của ảnh trên Unsplash

  UnsplashPhoto({
    required this.id,
    required this.photographer,
    required this.imageUrl,
    required this.downloadUrl,
    required this.url,
  });

  factory UnsplashPhoto.fromJson(Map<String, dynamic> json) {
    return UnsplashPhoto(
      id: json['id'],
      photographer: json['user']['name'] ?? 'Unknown',
      imageUrl: json['urls']['regular'] ?? '',
      downloadUrl: json['links']['download'] ?? '',
      url: json['links']['html'] ?? '',
    );
  }
}
