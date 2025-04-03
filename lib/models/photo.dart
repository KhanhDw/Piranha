class Photo {
  final int id;
  final String photographer;
  final String imageUrl;
  final String downloadUrl;

  Photo({
    required this.id,
    required this.photographer,
    required this.imageUrl,
    required this.downloadUrl,
  });

    factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      photographer: json['photographer'],
      imageUrl: json['src']['large2x'] ?? json['src']['original'] ?? '',
      downloadUrl: json['src']['original'] ?? '',
    );
  }

}