class PexelsPhoto {
  final int id;
  final String photographer;
  final String imageUrl;
  final String downloadUrl;

  PexelsPhoto({
    required this.id,
    required this.photographer,
    required this.imageUrl,
    required this.downloadUrl,
  });

  factory PexelsPhoto.fromJson(Map<String, dynamic> json) {
    return PexelsPhoto(
      id: json['id'],
      photographer: json['photographer'],
      imageUrl: json['src']['large2x'] ?? json['src']['original'] ?? '',
      downloadUrl: json['src']['original'] ?? '',
    );
  }
}
